defmodule Milvex.Milvus.Proto.Rg.ResourceGroupConfig do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :requests, 1, type: Milvex.Milvus.Proto.Rg.ResourceGroupLimit
  field :limits, 2, type: Milvex.Milvus.Proto.Rg.ResourceGroupLimit

  field :transfer_from, 3,
    repeated: true,
    type: Milvex.Milvus.Proto.Rg.ResourceGroupTransfer,
    json_name: "transferFrom"

  field :transfer_to, 4,
    repeated: true,
    type: Milvex.Milvus.Proto.Rg.ResourceGroupTransfer,
    json_name: "transferTo"

  field :node_filter, 5,
    type: Milvex.Milvus.Proto.Rg.ResourceGroupNodeFilter,
    json_name: "nodeFilter"
end
