import Blob "mo:base/Blob";
import Time "mo:base/Time";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Result "mo:base/Result";
import Hash "mo:base/Hash";

import { cancelTimer; setTimer } = "mo:⛔";
import Timer "mo:base/Timer";

import Types "types/types";
// import States "modules/triemap-states"; 
import States "modules/hashmap-states"; 
import Interfaces "modules/interfaces";
import Const "modules/const";
 
import Fuzz "mo:fuzz";

import Debug "mo:base/Debug";

module{

    public type MsgId = Types.MsgId;
    public type Time = Types.Time;
    public type MessageType = Types.MessageType;//#NEW;#ACK;#FIN 
    public type MessageStatus = Types.MessageStatus;
    public type Scaner = Types.Scaner; //#OFF;#ON
    public type Config = Types.Config;

    //Interfaces
    public type ICanisterReceiver = Interfaces.ICanisterReceiver;
    public type ICanisterSender = Interfaces.ICanisterSender;

    public let DEFAULT_CONFIG : Config = Const.default_config;

    public class Sender(
        config: Config){

        private let CONFIG = config;  

        private var states = States.Storage();
        private let fuzz = Fuzz.Fuzz();
        private var timer_id = 0;

        public func entries(): Iter.Iter<(MsgId, MessageStatus)>{ return states.entries(); };
        public func status_scaner(): Scaner{ return states.scaner; };
        public func clear() {states.clear();};
        public func count(): Nat {return states.count();};
        public func message_default(): ?MessageStatus {return states.message_default();};
        public func collection_by_time(): [?MessageStatus]{ 
            return states.collection_by_time(
                CONFIG.NUMBER_SHIPMENTS_ROUND, CONFIG.WAITING_TIME);};
        //Scaner
        public func scan(): async* (){
            // we stop the scaner if there are no queues 
            if(states.count() == 0){ stop_scaner(); };
            let msgs_status = states.collection_by_time(
                CONFIG.NUMBER_SHIPMENTS_ROUND, CONFIG.WAITING_TIME);
            for(msg_status in msgs_status.vals()){
                switch(msg_status){
                    case(null){ };
                    case(?msg_status){
                        if(msg_status.attempts > CONFIG.ATTEMPTS_NEW_MSG){//10
                            Debug.print("(SENDER) FORGET MESSANGE - UNSUCCESSFULLY: " # debug_show(msg_status.processed));
                            states.forget(msg_status);
                        }
                        else{
                            let canister_receiver: ICanisterReceiver = actor(msg_status.caller_id);
                            switch(msg_status.message_type){
                                case(#NEW(new)){
                                    let new_msg_status: MessageStatus = states.creating_msg_status(
                                        msg_status.message_type, 
                                        msg_status.processed,
                                        msg_status.attempts + 1, 
                                        Time.now(), //new time for next attempt
                                        msg_status.caller_id ,
                                    );
                                    let res = states.replace(new.msg_id, new_msg_status);
                                    canister_receiver.com_asyncFlow_newMessage(msg_status.message_type);//NEW 
                                };
                                case(#ACK(ack)){};
                                case(#FIN(fin)){};
                            };
                        };
                    };           
                };
            };
        };
        //System scaner
        private func job_scaner(): async(){ // async* https://forum.dfinity.org/t/system-timer-support-async/18624
            Debug.print("(SENDER) JOB_SCANER");
            switch(status_scaner()) {
                case(#ON){ await* scan(); };
                case(#OFF) {};
            }; 
        };
        public func stop_scaner() { 
            Debug.print("(SENDER) STOP_SCANER");
            Timer.cancelTimer(timer_id);
            timer_id := 0;
            states.scaner := #OFF  
        }; 
        public func start_scaner(){ 
            switch(status_scaner()) {
                case(#ON){ };
                case(#OFF) {
                    Debug.print("(SENDER) START_SCANER");
                    timer_id := Timer.recurringTimer(CONFIG.PERIOD_DURATION, job_scaner); // async*
                    states.scaner := #ON 
                };
            }; 
        }; 
        public func restart_scaner(){ 
             switch(status_scaner()) {
                case(#ON){ };
                case(#OFF) {
                    stop_scaner();
                    clear();
                    start_scaner();
                    Debug.print("(SENDER) RESTART_SCANER");
                };
            };
        };   

        public func new_message(
            canister_id: Text,
            payload: Blob): async* (){
            start_scaner();// we start the scaner so there is a risk of queues

            let rand = fuzz.nat32.random();
            let msg_id: MsgId = Nat32.toNat(rand);

            let canister_receiver: ICanisterReceiver = actor(canister_id);
            let msg: MessageType = states.creating_msg_new(msg_id, payload);
            let msg_status: MessageStatus = states.creating_msg_status(msg, false, 0, Time.now(), canister_id);
            let result = ignore states.put(msg_id, msg_status);
            canister_receiver.com_asyncFlow_newMessage(msg);
            Debug.print("(SENDER) NEW MESSANGE - MSG_ID: " # debug_show(msg_id));
        };

        public func com_asyncFlow_ack(msg: MessageType, caller: Principal): async* (){
            let canister_receiver: ICanisterReceiver = actor(Principal.toText(caller));
            //start_scaner();//if the effect of racing ???
            switch(msg){
                case(#NEW(new)){ };
                case(#ACK(ack)){ 
                    let old_msg: ?MessageStatus = states.remove(ack.msg_id);
                    switch(old_msg){
                        //messages that have been completed have been deleted in the sender, 
                        //messages in the recipient will also be cleared after a certain number of attempts
                        case(null){};//msg_id deleted or fake or error id
                        case(?old_msg){
                            let fin_msg: MessageType = states.creating_msg_fin(ack.msg_id);
                            canister_receiver.com_asyncFlow_fin(fin_msg);//FIN
                        };
                    };
                };
                case(#FIN(fin)){};
            };
        };
    };

    public class Receiver(
        config: Config, 
        handler: Blob -> async* Blob){

        private let CONFIG = config;
        private var states = States.Storage();
        private var timer_id = 0;

        public let action = handler;
  
        public func entries(): Iter.Iter<(MsgId, MessageStatus)>{ return states.entries(); };
        public func status_scaner(): Scaner{ return states.scaner; };
        public func clear() {states.clear();};
        public func count(): Nat {return states.count();};
        public func message_default(): ?MessageStatus {return states.message_default();};
        public func collection_by_time(): [?MessageStatus]{ 
            return states.collection_by_time(
                CONFIG.NUMBER_SHIPMENTS_ROUND, CONFIG.WAITING_TIME);};

        private func HANDLER(payload: Blob): async* Blob{
            let result = await* action(payload); 
            return result;
        };   

        //Scaner
        public func scan(): async*(){
            // we stop the scaner if there are no queues 
            if(states.count() == 0){ stop_scaner(); };
            let msgs_status = states.collection_by_time(
                CONFIG.NUMBER_SHIPMENTS_ROUND, CONFIG.WAITING_TIME);
            for(msg_status in msgs_status.vals()){
                switch(msg_status){
                    case(null){};
                    case(?msg_status){
                        if(msg_status.attempts > CONFIG.ATTEMPTS_ACK_MSG){//10
                            //messages that have been completed have been deleted in the sender, 
                            //messages in the recipient will also be cleared after a certain number of attempts
                            Debug.print("(RECEIVER) FORGET MESSANGE UNSUCCESSFULLY RESULT PROCESSED: " # debug_show(msg_status.processed));
                            states.forget(msg_status);//FIN
                        }
                        else{
                            let canister_sender: ICanisterSender = actor(msg_status.caller_id);
                            switch(msg_status.message_type){
                                case(#NEW(new)){};
                                case(#ACK(ack)){
                                    let new_msg_status: MessageStatus = states.creating_msg_status(
                                        msg_status.message_type,
                                        msg_status.processed,
                                        msg_status.attempts + 1, 
                                        Time.now(), //new time for next attempt
                                        msg_status.caller_id,
                                    );
                                    let res = ignore states.replace(ack.msg_id, new_msg_status);
                                    canister_sender.com_asyncFlow_ack(msg_status.message_type);//ACK 
                                };
                                case(#FIN(fin)){};
                            };
                        };
                    };
                };
            };
        };

        //System scaner
        private func job_scaner(): async (){// async* https://forum.dfinity.org/t/system-timer-support-async/18624
            Debug.print("(RECEIVER) JOB_SCANER");
            switch(status_scaner()) {
                case(#ON){ await* scan(); };
                case(#OFF) {};
            }; 
        };
        public func stop_scaner() { 
            Debug.print("(RECEIVER) STOP_SCANER");
            Timer.cancelTimer(timer_id);
            timer_id := 0;
            states.scaner := #OFF  
        }; 
        public func start_scaner(){ 
            switch(status_scaner()) {
                case(#ON){ };
                case(#OFF) {
                    Debug.print("(RECEIVER) START_SCANER");
                    timer_id := Timer.recurringTimer(CONFIG.PERIOD_DURATION, job_scaner);// async*
                    states.scaner := #ON 
                };
            }; 
        }; 
        public func restart_scaner(){ 
             switch(status_scaner()) {
                case(#ON){ };
                case(#OFF) {
                    stop_scaner();
                    clear();
                    start_scaner();
                    Debug.print("(RECEIVER) RESTART_SCANER");
                };
            };
        };   
        
        public func com_asyncFlow_newMessage(msg: MessageType, caller: Principal): async* (){   
            start_scaner(); // we start the scaner so there is a risk of queues
            let canister_sender: ICanisterSender = actor(Principal.toText(caller));
            switch(msg){
                case(#NEW(new)){
                    var old_msg = states.get(new.msg_id);
                    switch(old_msg){
                        //new msg
                        case(null){
                            // let processed_payload: Blob = await HANDLER(new.msg_id, new.payload);
                            let processed_payload: Blob = await* HANDLER(new.payload);
                            let msg: MessageType = states.creating_msg_ack(new.msg_id, processed_payload);
                            let msg_status: MessageStatus = states.creating_msg_status(msg, true, 0, Time.now(), Principal.toText(caller));
                            let result = ignore states.put(new.msg_id, msg_status);
                            canister_sender.com_asyncFlow_ack(msg);//ACK                  
                        };
                        //old msg
                        case(?old_msg){
                            //possibly unreachable operation
                            if(old_msg.processed == false){ 
                                // let processed_payload: Blob = await HANDLER(new.msg_id, new.payload);
                                let processed_payload: Blob = await* HANDLER(new.payload);
                                let msg: MessageType = states.creating_msg_ack(new.msg_id, processed_payload);
                                let msg_status: MessageStatus = states.creating_msg_status(msg, true, old_msg.attempts + 1, Time.now(), Principal.toText(caller));
                                let res = ignore states.replace(new.msg_id, msg_status);
                                canister_sender.com_asyncFlow_ack(msg);//ACK 
                            }
                            else{ 
                                canister_sender.com_asyncFlow_ack(old_msg.message_type);//ACK 
                            }; 
                        };
                    };
                };
                case(#ACK(ack)){};
                case(#FIN(fin)){};
            };
        };

        public func com_asyncFlow_fin(msg: MessageType){
            switch(msg){
                case(#NEW(new)){};
                case(#ACK(ack)){};
                case(#FIN(fin)){ 
                    Debug.print("#FIN (RECEIVER) SUCCESSFULLY - MSG_ID: " # debug_show(fin.msg_id));
                    states.delete(fin.msg_id);//FIN
                };
            };
        };    
    };
};  