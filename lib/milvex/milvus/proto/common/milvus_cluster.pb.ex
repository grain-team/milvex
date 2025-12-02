defmodule Milvex.Milvus.Proto.Common.MilvusCluster do
  @moduledoc """
  MilvusCluster describes the Milvus cluster information, 
  including pchannel mapping details.
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :cluster_id, 1, type: :string, json_name: "clusterId"

  field :connection_param, 2,
    type: Milvex.Milvus.Proto.Common.ConnectionParam,
    json_name: "connectionParam"

  field :pchannels, 3, repeated: true, type: :string
end
