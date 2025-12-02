defmodule Milvex.Milvus.Proto.Milvus.PersistentSegmentInfo do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :segmentID, 1, type: :int64
  field :collectionID, 2, type: :int64
  field :partitionID, 3, type: :int64
  field :num_rows, 4, type: :int64, json_name: "numRows"
  field :state, 5, type: Milvex.Milvus.Proto.Common.SegmentState, enum: true
  field :level, 6, type: Milvex.Milvus.Proto.Common.SegmentLevel, enum: true
  field :is_sorted, 7, type: :bool, json_name: "isSorted"
  field :storage_version, 8, type: :int64, json_name: "storageVersion"
end
