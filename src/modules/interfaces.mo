import Blob "mo:base/Blob";
import Hash "mo:base/Hash";
import Types "../types/types";

module{  
    type MessageType = Types.MessageType;
    type MsgId = Types.MsgId;

    public type ICanisterReceiver = actor{
        com_asyncFlow_newMessage: (msg: MessageType) -> ();
        com_asyncFlow_fin: (msg: MessageType) -> ();
    };
    
    public type ICanisterSender = actor{
        com_asyncFlow_ack: (msg: MessageType) -> ();
        new_message: (canister_id: Text, msg_val: Blob) -> ();//test
    };

}