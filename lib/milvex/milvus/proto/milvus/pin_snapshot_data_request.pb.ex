defmodule Milvex.Milvus.Proto.Milvus.PinSnapshotDataRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :name, 2, type: :string
  field :db_name, 3, type: :string, json_name: "dbName"
  field :collection_name, 4, type: :string, json_name: "collectionName"
  field :ttl_seconds, 5, type: :int64, json_name: "ttlSeconds"
end
