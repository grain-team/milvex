defmodule Milvex.Milvus.Proto.Milvus.TransferNodeRequest do
  @moduledoc """
  transfer `nodeNum` nodes from `source_resource_group` to `target_resource_group`
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :source_resource_group, 2, type: :string, json_name: "sourceResourceGroup"
  field :target_resource_group, 3, type: :string, json_name: "targetResourceGroup"
  field :num_node, 4, type: :int32, json_name: "numNode"
end
