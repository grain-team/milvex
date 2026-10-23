defmodule Milvex.Milvus.Proto.Milvus.RefreshExternalCollectionJobInfo do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :job_id, 1, type: :int64, json_name: "jobId"
  field :collection_name, 2, type: :string, json_name: "collectionName"
  field :state, 3, type: Milvex.Milvus.Proto.Milvus.RefreshExternalCollectionState, enum: true
  field :progress, 4, type: :int64
  field :reason, 5, type: :string
  field :external_source, 6, type: :string, json_name: "externalSource"
  field :start_time, 7, type: :int64, json_name: "startTime"
  field :end_time, 8, type: :int64, json_name: "endTime"
  field :external_spec, 9, type: :string, json_name: "externalSpec"
end
