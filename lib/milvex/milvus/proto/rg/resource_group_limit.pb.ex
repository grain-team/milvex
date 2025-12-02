defmodule Milvex.Milvus.Proto.Rg.ResourceGroupLimit do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :node_num, 1, type: :int32, json_name: "nodeNum"
end
