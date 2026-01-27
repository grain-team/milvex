defmodule Milvex.Milvus.Proto.Milvus.FlushAllResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :flush_all_ts, 2, type: :uint64, json_name: "flushAllTs", deprecated: true

  field :flush_results, 3,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.FlushAllResult,
    json_name: "flushResults",
    deprecated: true

  field :flush_all_msgs, 4,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.FlushAllResponse.FlushAllMsgsEntry,
    json_name: "flushAllMsgs",
    map: true

  field :cluster_info, 5, type: Milvex.Milvus.Proto.Milvus.ClusterInfo, json_name: "clusterInfo"
end
