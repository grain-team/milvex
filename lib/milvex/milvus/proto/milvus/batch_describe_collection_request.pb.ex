defmodule Milvex.Milvus.Proto.Milvus.BatchDescribeCollectionRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :db_name, 1, type: :string, json_name: "dbName"
  field :collection_name, 2, repeated: true, type: :string, json_name: "collectionName"
  field :collectionID, 3, repeated: true, type: :int64
end
