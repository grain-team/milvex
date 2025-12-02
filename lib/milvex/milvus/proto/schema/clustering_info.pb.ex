defmodule Milvex.Milvus.Proto.Schema.ClusteringInfo do
  @moduledoc """
  clustering distribution info of a certain data unit, it can be segment, partition, etc.
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :vector_clustering_infos, 1,
    repeated: true,
    type: Milvex.Milvus.Proto.Schema.VectorClusteringInfo,
    json_name: "vectorClusteringInfos"

  field :scalar_clustering_infos, 2,
    repeated: true,
    type: Milvex.Milvus.Proto.Schema.ScalarClusteringInfo,
    json_name: "scalarClusteringInfos"
end
