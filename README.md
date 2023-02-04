# Motoko mal library

### 1. Check system requirements
- [Node.js](https://nodejs.org/)
- [DFX](https://internetcomputer.org/docs/current/developer-docs/quickstart/local-quickstart) >= 0.10.0
- [Moc](https://github.com/dfinity/motoko/releases) >= 0.8.1

## Setup MOPS
Configure this package manager
Follow the instructions
- https://mops.one/docs/install
- https://github.com/ZenVoich/mops

# Mal
### Version: 0.0.24
A library for processing data between containers. Uses multiple attempts to send a request. Use multiple attempts to confirm the request with the result.

![image](mal.png)

## Install Mal
```
mops add mal
```
```
mops install
```

## Import
```motoko
import Mal "mo:mal";
```
## Example
### 1 Important parameters
- Number of attempts by the sender:
ATTEMPTS_NEW_MSG > 1
- Number of attempts by the receiver:
ATTEMPTS_ACK_MSG > 1
- System time!!!:
WAITING_TIME = 330_000_000_000;
- System time!!!(not using)
QUEUE_TIME = 300_000_000_000; 
- Scan interval for queue detection:
PERIOD_HEARTBEAT >= 500_000_000
PERIOD_DURATION >= 500_000_000
- Number of requests to resend: 
NUMBER_SHIPMENTS_ROUND > 0

### 1.1 Default parameters

- ATTEMPTS_NEW_MSG = 10;                                              
- ATTEMPTS_ACK_MSG =10;                                       
- QUEUE_TIME = 300_000_000_000;                               
- WAITING_TIME = 330_000_000_000;                             
- NUMBER_SHIPMENTS_ROUND = 10;                             
- PERIOD_HEARTBEAT = 5_000_000_000;  
- PERIOD_DURATION = #nanoseconds 5_000_000_000;

### 2.1 Detailed example

- https://github.com/fury02/example-async-data-deliveries

### 2.2 Add code
### Sample Sender
```motoko
import Text "mo:base/Text";
import Mal "../lib";
actor Sender{ 
    type MessageType = Mal.MessageType;//#NEW;#ACK;#FIN 
    type Config = Mal.Config;
    private var CONFIG : Config = Mal.DEFAULT_CONFIG;
    var lib = Mal.Sender(CONFIG);
    //result from the receiver
    private func HANDLER(
        msg: MessageType){
        switch(msg){
            case(#NEW(new)){ };
            case(#ACK(ack)){ 
                //**Your any code**//
            };
            case(#FIN(fin)){};
        };
    };
    //messages
    public func new_message(
        canister_id: Text, 
        payload: Blob){
        await* lib.new_message(canister_id, payload);
    };
    public shared({caller}) func com_asyncFlow_ack(
        msg: MessageType){ 
        HANDLER(msg);
        await* lib.com_asyncFlow_ack(msg, caller);
    };
}

```
### Sample Receiver
```motoko
import Text "mo:base/Text";
import Mal "../lib";
actor Receiver{
    type MessageType = Mal.MessageType;//#NEW;#ACK;#FIN 
    type Config = Mal.Config;
    private var CONFIG : Config = Mal.DEFAULT_CONFIG;
    private func handler(
        payload: Blob): async* Blob {
            //**Your any code**//
        return Text.encodeUtf8("");//plug
    };
    var lib = Mal.Receiver(CONFIG, handler);
    //messages
    public shared({caller}) func com_asyncFlow_newMessage(
        msg: MessageType){   
        await* lib.com_asyncFlow_newMessage(msg, caller);
    };
    public shared({caller}) func com_asyncFlow_fin(
        msg: MessageType){
        lib.com_asyncFlow_fin(msg);
    };
}

```

## History
- Version: 0.0.23 (first stable)
- Version: 0.0.24 (timer, scaner: optimization )
- Version: 0.0.25 (corrections: restart_scaner, refractoring)
- Version: 0.0.26 (async* await*)