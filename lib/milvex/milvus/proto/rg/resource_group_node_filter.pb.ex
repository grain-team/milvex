defmodule Milvex.Milvus.Proto.Rg.ResourceGroupNodeFilter do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :node_labels, 1,
    repeated: true,
    type: Milvex.Milvus.Proto.Common.KeyValuePair,
    json_name: "nodeLabels"
end
