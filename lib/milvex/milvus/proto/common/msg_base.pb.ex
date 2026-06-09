defmodule Milvex.Milvus.Proto.Common.MsgBase do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :msg_type, 1, type: Milvex.Milvus.Proto.Common.MsgType, json_name: "msgType", enum: true
  field :msgID, 2, type: :int64
  field :timestamp, 3, type: :uint64
  field :sourceID, 4, type: :int64
  field :targetID, 5, type: :int64

  field :properties, 6,
    repeated: true,
    type: Milvex.Milvus.Proto.Common.MsgBase.PropertiesEntry,
    map: true

  field :replicateInfo, 7, type: Milvex.Milvus.Proto.Common.ReplicateInfo
end
