defmodule Milvex.Milvus.Proto.Milvus.GetCompactionStateResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :state, 2, type: Milvex.Milvus.Proto.Common.CompactionState, enum: true
  field :executingPlanNo, 3, type: :int64
  field :timeoutPlanNo, 4, type: :int64
  field :completedPlanNo, 5, type: :int64
  field :failedPlanNo, 6, type: :int64
end
