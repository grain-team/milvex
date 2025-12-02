defmodule Milvex.Milvus.Proto.Rg.ResourceGroupTransfer do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :resource_group, 1, type: :string, json_name: "resourceGroup"
end
