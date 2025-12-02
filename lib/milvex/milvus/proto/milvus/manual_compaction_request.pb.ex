defmodule Milvex.Milvus.Proto.Milvus.ManualCompactionRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :collectionID, 1, type: :int64
  field :timetravel, 2, type: :uint64
  field :majorCompaction, 3, type: :bool
  field :collection_name, 4, type: :string, json_name: "collectionName"
  field :db_name, 5, type: :string, json_name: "dbName"
  field :partition_id, 6, type: :int64, json_name: "partitionId"
  field :channel, 7, type: :string
  field :segment_ids, 8, repeated: true, type: :int64, json_name: "segmentIds"
  field :l0Compaction, 9, type: :bool
  field :target_size, 10, type: :int64, json_name: "targetSize"
end
