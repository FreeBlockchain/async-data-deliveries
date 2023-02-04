import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export interface MessageStatus {
  'creation_time' : Time,
  'attempts' : number,
  'caller_id' : string,
  'message_type' : MessageType,
  'processed' : boolean,
}
export type MessageType = {
    'ACK' : { 'msg_id' : MsgId, 'payload' : Uint8Array | number[] }
  } |
  { 'FIN' : { 'msg_id' : MsgId } } |
  { 'NEW' : { 'msg_id' : MsgId, 'payload' : Uint8Array | number[] } };
export type MessageType__1 = {
    'ACK' : { 'msg_id' : MsgId, 'payload' : Uint8Array | number[] }
  } |
  { 'FIN' : { 'msg_id' : MsgId } } |
  { 'NEW' : { 'msg_id' : MsgId, 'payload' : Uint8Array | number[] } };
export type MsgId = bigint;
export type Scaner = { 'ON' : null } |
  { 'OFF' : null };
export type Time = bigint;
export interface _SERVICE {
  'clear' : ActorMethod<[], undefined>,
  'collection_by_time' : ActorMethod<[], Array<[] | [MessageStatus]>>,
  'com_asyncFlow_ack' : ActorMethod<[MessageType__1], undefined>,
  'count' : ActorMethod<[], bigint>,
  'message_default' : ActorMethod<[], [] | [MessageStatus]>,
  'new_message' : ActorMethod<[string, Uint8Array | number[]], undefined>,
  'restart_scaner' : ActorMethod<[], undefined>,
  'start_scaner' : ActorMethod<[], undefined>,
  'status_scaner' : ActorMethod<[], Scaner>,
  'stop_scaner' : ActorMethod<[], undefined>,
}
