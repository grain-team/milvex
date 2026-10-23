defmodule Milvex.Milvus.Proto.Schema.FunctionChainExpr do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :name, 1, type: :string
  field :args, 2, repeated: true, type: Milvex.Milvus.Proto.Schema.FunctionChainExprArg

  field :params, 3,
    repeated: true,
    type: Milvex.Milvus.Proto.Schema.FunctionChainExpr.ParamsEntry,
    map: true
end
