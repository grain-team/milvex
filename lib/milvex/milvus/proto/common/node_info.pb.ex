defmodule Milvex.Milvus.Proto.Common.NodeInfo do
  @moduledoc """
  NodeInfo is used to describe the node information.
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :node_id, 1, type: :int64, json_name: "nodeId"
  field :address, 2, type: :string
  field :hostname, 3, type: :string
end
