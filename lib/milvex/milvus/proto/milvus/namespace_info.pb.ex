defmodule Milvex.Milvus.Proto.Milvus.NamespaceInfo do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :collection_name, 1, type: :string, json_name: "collectionName"
  field :namespace_name, 2, type: :string, json_name: "namespaceName"
  field :created_timestamp, 3, type: :uint64, json_name: "createdTimestamp"
  field :created_utc_timestamp, 4, type: :uint64, json_name: "createdUtcTimestamp"
  field :state, 5, type: :string
  field :stats, 6, type: Milvex.Milvus.Proto.Milvus.NamespaceStats
end
