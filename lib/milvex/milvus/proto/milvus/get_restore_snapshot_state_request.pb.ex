defmodule Milvex.Milvus.Proto.Milvus.GetRestoreSnapshotStateRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :job_id, 2, type: :int64, json_name: "jobId"
end
