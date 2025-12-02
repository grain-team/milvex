defmodule Milvex.Milvus.Proto.Milvus.ManualCompactionResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :compactionID, 2, type: :int64
  field :compactionPlanCount, 3, type: :int32
end
