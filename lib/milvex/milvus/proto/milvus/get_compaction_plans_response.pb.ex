defmodule Milvex.Milvus.Proto.Milvus.GetCompactionPlansResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :state, 2, type: Milvex.Milvus.Proto.Common.CompactionState, enum: true
  field :mergeInfos, 3, repeated: true, type: Milvex.Milvus.Proto.Milvus.CompactionMergeInfo
end
