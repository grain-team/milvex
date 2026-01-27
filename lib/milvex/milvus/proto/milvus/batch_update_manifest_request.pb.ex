defmodule Milvex.Milvus.Proto.Milvus.BatchUpdateManifestRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName"
  field :collection_name, 3, type: :string, json_name: "collectionName"
  field :field_names, 4, repeated: true, type: :string, json_name: "fieldNames"
  field :items, 5, repeated: true, type: Milvex.Milvus.Proto.Milvus.BatchUpdateManifestItem
end
