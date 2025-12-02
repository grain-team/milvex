defmodule Milvex.Milvus.Proto.Milvus.DescribeResourceGroupResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status

  field :resource_group, 2,
    type: Milvex.Milvus.Proto.Milvus.ResourceGroup,
    json_name: "resourceGroup"
end
