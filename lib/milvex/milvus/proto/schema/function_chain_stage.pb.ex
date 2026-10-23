defmodule Milvex.Milvus.Proto.Schema.FunctionChainStage do
  @moduledoc """
  beta, api may change
  Function chain APIs, including FunctionChainStage and related FunctionChain messages,
  are experimental and may change in future releases.
  """

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :FunctionChainStageUnspecified, 0
  field :FunctionChainStageIngestion, 1
  field :FunctionChainStagePreProcess, 2
  field :FunctionChainStageL0Rerank, 3
  field :FunctionChainStageL1Rerank, 4
  field :FunctionChainStageL2Rerank, 5
  field :FunctionChainStagePostProcess, 6
end
