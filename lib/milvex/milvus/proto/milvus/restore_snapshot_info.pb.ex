defmodule Milvex.Milvus.Proto.Milvus.RestoreSnapshotInfo do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :job_id, 1, type: :int64, json_name: "jobId"
  field :snapshot_name, 2, type: :string, json_name: "snapshotName"
  field :db_name, 3, type: :string, json_name: "dbName"
  field :collection_name, 4, type: :string, json_name: "collectionName"
  field :state, 5, type: Milvex.Milvus.Proto.Milvus.RestoreSnapshotState, enum: true
  field :progress, 6, type: :int32
  field :reason, 7, type: :string
  field :start_time, 8, type: :uint64, json_name: "startTime"
  field :time_cost, 9, type: :uint64, json_name: "timeCost"
end
