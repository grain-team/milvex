defmodule Milvex.Milvus.Proto.Milvus.QuerySegmentInfo do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :segmentID, 1, type: :int64
  field :collectionID, 2, type: :int64
  field :partitionID, 3, type: :int64
  field :mem_size, 4, type: :int64, json_name: "memSize"
  field :num_rows, 5, type: :int64, json_name: "numRows"
  field :index_name, 6, type: :string, json_name: "indexName"
  field :indexID, 7, type: :int64
  field :nodeID, 8, type: :int64, deprecated: true
  field :state, 9, type: Milvex.Milvus.Proto.Common.SegmentState, enum: true
  field :nodeIds, 10, repeated: true, type: :int64
  field :level, 11, type: Milvex.Milvus.Proto.Common.SegmentLevel, enum: true
  field :is_sorted, 12, type: :bool, json_name: "isSorted"
  field :storage_version, 13, type: :int64, json_name: "storageVersion"
end
