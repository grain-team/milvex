defmodule Milvex.Milvus.Proto.Milvus.ExportSnapshotInfo do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :job_id, 1, type: :int64, json_name: "jobId"
  field :snapshot_name, 2, type: :string, json_name: "snapshotName"
  field :db_name, 3, type: :string, json_name: "dbName"
  field :collection_name, 4, type: :string, json_name: "collectionName"
  field :state, 5, type: Milvex.Milvus.Proto.Milvus.ExportSnapshotState, enum: true
  field :progress, 6, type: :int32
  field :reason, 7, type: :string
  field :start_time, 8, type: :uint64, json_name: "startTime"
  field :time_cost, 9, type: :uint64, json_name: "timeCost"
  field :total_files, 10, type: :int64, json_name: "totalFiles"
  field :copied_files, 11, type: :int64, json_name: "copiedFiles"
  field :snapshot_metadata_uri, 12, type: :string, json_name: "snapshotMetadataUri"
  field :total_bytes, 13, type: :int64, json_name: "totalBytes"
end
