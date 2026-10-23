defmodule Milvex.Milvus.Proto.Milvus.GetRefreshExternalCollectionProgressResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status

  field :job_info, 2,
    type: Milvex.Milvus.Proto.Milvus.RefreshExternalCollectionJobInfo,
    json_name: "jobInfo"
end
