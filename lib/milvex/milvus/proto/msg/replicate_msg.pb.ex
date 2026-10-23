defmodule Milvex.Milvus.Proto.Msg.ReplicateMsg do
  use Protobuf, deprecated: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :is_end, 2, type: :bool, json_name: "isEnd"
  field :is_cluster, 3, type: :bool, json_name: "isCluster"
  field :database, 4, type: :string
  field :collection, 5, type: :string
end
