defmodule Milvex.Milvus.Proto.Milvus.GetNamespaceStatsResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :namespace_name, 2, type: :string, json_name: "namespaceName"
  field :stats, 3, type: Milvex.Milvus.Proto.Milvus.NamespaceStats
end
