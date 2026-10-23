defmodule Milvex.Milvus.Proto.Milvus.GetRLSPrincipalTagsResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :tags, 2, type: :string
  field :db_name, 3, type: :string, json_name: "dbName"
  field :collection_name, 4, type: :string, json_name: "collectionName"
  field :principal_name, 5, type: :string, json_name: "principalName"
end
