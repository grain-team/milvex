defmodule Milvex.Milvus.Proto.Milvus.GetReplicasRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :collectionID, 2, type: :int64
  field :with_shard_nodes, 3, type: :bool, json_name: "withShardNodes"
  field :collection_name, 4, type: :string, json_name: "collectionName"
  field :db_name, 5, type: :string, json_name: "dbName"
end
