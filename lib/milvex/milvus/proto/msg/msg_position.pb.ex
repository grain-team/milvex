defmodule Milvex.Milvus.Proto.Msg.MsgPosition do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :channel_name, 1, type: :string, json_name: "channelName"
  field :msgID, 2, type: :bytes
  field :msgGroup, 3, type: :string
  field :timestamp, 4, type: :uint64
  field :WAL_name, 5, type: Milvex.Milvus.Proto.Common.WALName, json_name: "WALName", enum: true
end
