export const idlFactory = ({ IDL }) => {
  const Time = IDL.Int;
  const MsgId = IDL.Nat;
  const MessageType = IDL.Variant({
    'ACK' : IDL.Record({ 'msg_id' : MsgId, 'payload' : IDL.Vec(IDL.Nat8) }),
    'FIN' : IDL.Record({ 'msg_id' : MsgId }),
    'NEW' : IDL.Record({ 'msg_id' : MsgId, 'payload' : IDL.Vec(IDL.Nat8) }),
  });
  const MessageStatus = IDL.Record({
    'creation_time' : Time,
    'attempts' : IDL.Nat16,
    'caller_id' : IDL.Text,
    'message_type' : MessageType,
    'processed' : IDL.Bool,
  });
  const MessageType__1 = IDL.Variant({
    'ACK' : IDL.Record({ 'msg_id' : MsgId, 'payload' : IDL.Vec(IDL.Nat8) }),
    'FIN' : IDL.Record({ 'msg_id' : MsgId }),
    'NEW' : IDL.Record({ 'msg_id' : MsgId, 'payload' : IDL.Vec(IDL.Nat8) }),
  });
  const Scaner = IDL.Variant({ 'ON' : IDL.Null, 'OFF' : IDL.Null });
  return IDL.Service({
    'clear' : IDL.Func([], [], ['oneway']),
    'collection_by_time' : IDL.Func([], [IDL.Vec(IDL.Opt(MessageStatus))], []),
    'com_asyncFlow_fin' : IDL.Func([MessageType__1], [], ['oneway']),
    'com_asyncFlow_newMessage' : IDL.Func([MessageType__1], [], ['oneway']),
    'count' : IDL.Func([], [IDL.Nat], []),
    'message_default' : IDL.Func([], [IDL.Opt(MessageStatus)], []),
    'restart_scaner' : IDL.Func([], [], ['oneway']),
    'start_scaner' : IDL.Func([], [], ['oneway']),
    'status_scaner' : IDL.Func([], [Scaner], []),
    'stop_scaner' : IDL.Func([], [], ['oneway']),
  });
};
export const init = ({ IDL }) => { return []; };
