defmodule Milvex.Milvus.Proto.Milvus.FlushCollectionResult.ChannelCpsEntry do
  use Protobuf, map: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :key, 1, type: :string
  field :value, 2, type: Milvex.Milvus.Proto.Msg.MsgPosition
end
