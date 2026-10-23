defmodule Milvex.Milvus.Proto.Schema.FunctionChainOp do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :op, 1, type: :string
  field :expr, 2, type: Milvex.Milvus.Proto.Schema.FunctionChainExpr
  field :inputs, 3, repeated: true, type: :string
  field :outputs, 4, repeated: true, type: :string

  field :params, 5,
    repeated: true,
    type: Milvex.Milvus.Proto.Schema.FunctionChainOp.ParamsEntry,
    map: true
end
