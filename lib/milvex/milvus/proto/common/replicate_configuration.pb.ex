defmodule Milvex.Milvus.Proto.Common.ReplicateConfiguration do
  @moduledoc """
  ReplicateConfiguration is the configuration that
  describes the replication topology cross multiple cluster milvus.
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :clusters, 1, repeated: true, type: Milvex.Milvus.Proto.Common.MilvusCluster

  field :cross_cluster_topology, 2,
    repeated: true,
    type: Milvex.Milvus.Proto.Common.CrossClusterTopology,
    json_name: "crossClusterTopology"
end
