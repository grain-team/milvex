defmodule Milvex.Milvus.Proto.Milvus.CreateResourceGroupRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :resource_group, 2, type: :string, json_name: "resourceGroup"
  field :config, 3, type: Milvex.Milvus.Proto.Rg.ResourceGroupConfig
end
