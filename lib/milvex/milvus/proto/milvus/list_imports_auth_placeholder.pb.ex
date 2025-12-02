defmodule Milvex.Milvus.Proto.Milvus.ListImportsAuthPlaceholder do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :db_name, 3, type: :string, json_name: "dbName"
  field :collection_name, 1, type: :string, json_name: "collectionName"
end
