defmodule Milvex.Milvus.Proto.Milvus.ListRowPoliciesResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :policies, 2, repeated: true, type: Milvex.Milvus.Proto.Milvus.RowPolicy
  field :db_name, 3, type: :string, json_name: "dbName"
  field :collection_name, 4, type: :string, json_name: "collectionName"
end
