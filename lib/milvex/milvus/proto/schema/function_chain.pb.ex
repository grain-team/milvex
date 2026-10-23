defmodule Milvex.Milvus.Proto.Schema.FunctionChain do
  @moduledoc """
  FunctionChain is an ordered public plan for function-based processing.
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :name, 1, type: :string
  field :stage, 2, type: Milvex.Milvus.Proto.Schema.FunctionChainStage, enum: true
  field :ops, 3, repeated: true, type: Milvex.Milvus.Proto.Schema.FunctionChainOp
end
