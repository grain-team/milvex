defmodule Milvex.Milvus.Proto.Common.CrossClusterTopology do
  @moduledoc """
  CrossClusterTopology is the topology that 
  describes the topology cross multiple cluster milvus.
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :source_cluster_id, 1, type: :string, json_name: "sourceClusterId"
  field :target_cluster_id, 2, type: :string, json_name: "targetClusterId"
end
