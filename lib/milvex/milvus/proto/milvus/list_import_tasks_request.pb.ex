defmodule Milvex.Milvus.Proto.Milvus.ListImportTasksRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :collection_name, 1, type: :string, json_name: "collectionName"
  field :limit, 2, type: :int64
  field :db_name, 3, type: :string, json_name: "dbName"
end
