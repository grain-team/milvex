defmodule Milvex.Milvus.Proto.Schema.FunctionChainExprArg do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :arg, 0

  field :column, 1, type: Milvex.Milvus.Proto.Schema.FunctionChainColumnArg, oneof: 0
  field :literal, 2, type: Milvex.Milvus.Proto.Schema.FunctionParamValue, oneof: 0
end
