defmodule Milvex.Milvus.Proto.Milvus.ReplicateMessageRequest do
  use Protobuf, deprecated: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :channel_name, 2, type: :string, json_name: "channelName"
  field :BeginTs, 3, type: :uint64
  field :EndTs, 4, type: :uint64
  field :Msgs, 5, repeated: true, type: :bytes
  field :StartPositions, 6, repeated: true, type: Milvex.Milvus.Proto.Msg.MsgPosition
  field :EndPositions, 7, repeated: true, type: Milvex.Milvus.Proto.Msg.MsgPosition
end
