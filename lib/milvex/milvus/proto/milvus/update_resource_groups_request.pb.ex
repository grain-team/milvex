defmodule Milvex.Milvus.Proto.Milvus.UpdateResourceGroupsRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase

  field :resource_groups, 2,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.UpdateResourceGroupsRequest.ResourceGroupsEntry,
    json_name: "resourceGroups",
    map: true
end
