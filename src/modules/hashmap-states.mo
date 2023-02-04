import Time "mo:base/Time";
import Blob "mo:base/Blob";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";

import Types "../types/types";

import Map "mo:stable-hash-map";

import Debug "mo:base/Debug";

module{
    type MsgId = Types.MsgId;//base type: Nat -> Nat32 
    type Time = Types.Time;  
    type MessageStatus = Types.MessageStatus; //#NEW;#ACK;#FIN; 
    type MessageType = Types.MessageType;
    type Scaner = Types.Scaner; //#OFF;#ON

    public class Storage(){

        private let { nhash } = Map;

        private var messages 
                    = Map.new<MsgId, MessageStatus>(nhash);
        
        public var scaner: Scaner = #OFF;

        public func put( msg_id: MsgId,  msg: MessageStatus) :?MessageStatus
                    = Map.put(messages, nhash, msg_id, msg); 

        public func replace( msg_id: MsgId,  msg: MessageStatus): ?MessageStatus {
            Map.delete(messages, nhash, msg_id);
            return Map.put(messages, nhash, msg_id, msg);
        };
                    
        public func get(msg_id: MsgId): ?MessageStatus 
                    = Map.get(messages, nhash, msg_id);

        public func delete(msg_id: MsgId) 
                    = Map.delete(messages, nhash, msg_id);

        public func clear() 
                    = Map.clear(messages);
        
        public func remove(msg_id: MsgId): ?MessageStatus {
            let result: ?MessageStatus = Map.get(messages, nhash, msg_id);
            Map.delete(messages, nhash, msg_id);
            return result;
        };
         
        public func count(): Nat = Map.size(messages);
        
        public func message_default(): ?MessageStatus{
            if(Map.size(messages) > 0){ 
                for(msg_status in Map.vals(messages)){
                    return ?msg_status;
                };
            };
            return null;
        };

        public func get_by_time(
            time: Time): ?MessageStatus{
            if(Map.size(messages)  > 0){ 
                for(msg_status in Map.vals(messages)){
                    if(Time.now() - msg_status.creation_time >= time){
                        return ?msg_status;
                    };
                };
            };
            return null;
        };

        public func collection_by_time(
            size: Nat16,
            time: Time): [?MessageStatus]{
            let sn: Nat = Nat16.toNat(size);
            var array = Array.init<?MessageStatus>(sn, null);
            var i : Nat = 0;
            if(Map.size(messages) > 0){ 
                for(msg_status in Map.vals(messages)){
                    if(Time.now() - msg_status.creation_time >= time){
                        if(i >= sn){
                            return Array.freeze<?MessageStatus>(array);
                        };
                        array[i] := ?msg_status;
                        i := i + 1;
                    };
                };
            };
            return Array.freeze<?MessageStatus>(array);
        };

        public func get_id(
            msg_status: MessageStatus): MsgId{
            switch(msg_status.message_type){
                case(#NEW(new)){ return new.msg_id };
                case(#ACK(ack)){ return ack.msg_id };
                case(#FIN(fin)){ return fin.msg_id; };
            };
        };

        public func creating_msg_new(
            msg_id: MsgId, 
            payload: Blob): MessageType{
            let msg_type: MessageType = #NEW {
                msg_id = msg_id; 
                payload = payload;
            };
            return msg_type;
        };

        public func creating_msg_ack(
            msg_id: MsgId, 
            payload: Blob): MessageType{
            let msg_type: MessageType = #ACK {
                msg_id = msg_id; 
                payload = payload;
            };
            return msg_type;
        };

        public func creating_msg_fin(
            msg_id: MsgId): MessageType{
            let msg_type: MessageType = #FIN {
                msg_id = msg_id;
            };
            return msg_type;
        };

        public func creating_msg_status(
            msg: MessageType,
            processed: Bool,
            attempts: Nat16,
            creation_time: Time,
            caller_id: Text): MessageStatus{
            let msg_status: MessageStatus = {
                message_type = msg; 
                processed = processed;
                attempts = attempts; 
                creation_time = creation_time; 
                caller_id = caller_id;
            };
            return msg_status;
        };

        public func forget(
            msg_status: MessageStatus){
            let msg_id = get_id(msg_status);
            delete(msg_id);
        };

        public func entries(): Iter.Iter<(MsgId, MessageStatus)>{
            return Map.entries(messages);
        };
    };
}