defmodule Milvex.Milvus.Proto.Milvus.ExportSnapshotResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status

  field :snapshot_metadata_uri, 2,
    type: :string,
    json_name: "snapshotMetadataUri",
    deprecated: true

  field :job_id, 3, type: :int64, json_name: "jobId"
end
