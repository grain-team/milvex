defmodule Milvex.Milvus.Proto.Milvus.ReplicateMessage do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :source_cluster_id, 1, type: :string, json_name: "sourceClusterId"
  field :message, 2, type: Milvex.Milvus.Proto.Common.ImmutableMessage
end
