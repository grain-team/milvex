defmodule Milvex.Milvus.Proto.Milvus.CompactionMergeInfo do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :sources, 1, repeated: true, type: :int64
  field :target, 2, type: :int64
  field :plan_id, 3, type: :int64, json_name: "planId"
  field :trigger_id, 4, type: :int64, json_name: "triggerId"
  field :collection_id, 5, type: :int64, json_name: "collectionId"
  field :partition_id, 6, type: :int64, json_name: "partitionId"
  field :channel, 7, type: :string
  field :type, 8, type: Milvex.Milvus.Proto.Common.CompactionType, enum: true
  field :state, 9, type: Milvex.Milvus.Proto.Common.CompactionTaskState, enum: true
  field :failure_reason, 10, type: :string, json_name: "failureReason"
  field :targets, 11, repeated: true, type: :int64
end
