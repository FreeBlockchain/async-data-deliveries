import Time "mo:base/Time";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
module {
    public type Time = Time.Time;
    public type MsgId = Nat;//Random digit this messange Id base type: Nat32
    //https://forum.dfinity.org/t/open-icdevs-org-bounty-39-async-flow-one-shot-motoko-6-000/17901/5
    public type MessageType = {
        #NEW : {msg_id: MsgId; payload: Blob};
        #ACK : {msg_id: MsgId; payload: Blob};
        #FIN : {msg_id: MsgId};
    };
    public type Duration = {
        #nanoseconds : Nat; 
        #seconds : Nat
    };
    public type Config  = {
        ATTEMPTS_NEW_MSG: Nat16;
        ATTEMPTS_ACK_MSG: Nat16;
        QUEUE_TIME: Time;
        WAITING_TIME: Int;
        NUMBER_SHIPMENTS_ROUND: Nat16;
        PERIOD_HEARTBEAT: Nat;
        PERIOD_DURATION: Duration;
    };
    public type MessageStatus = {
        message_type: MessageType;
        processed: Bool;
        attempts: Nat16;
        creation_time: Time;
        caller_id: Text;
    };
    public type Scaner = {
        #OFF;
        #ON;
    };
}