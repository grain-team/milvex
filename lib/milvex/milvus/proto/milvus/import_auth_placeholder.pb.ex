defmodule Milvex.Milvus.Proto.Milvus.ImportAuthPlaceholder do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :db_name, 1, type: :string, json_name: "dbName"
  field :collection_name, 2, type: :string, json_name: "collectionName"
  field :partition_name, 3, type: :string, json_name: "partitionName"
end
