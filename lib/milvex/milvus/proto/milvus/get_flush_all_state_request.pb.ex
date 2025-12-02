defmodule Milvex.Milvus.Proto.Milvus.GetFlushAllStateRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :flush_all_ts, 2, type: :uint64, json_name: "flushAllTs", deprecated: true
  field :db_name, 3, type: :string, json_name: "dbName", deprecated: true

  field :flush_targets, 4,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.FlushAllTarget,
    json_name: "flushTargets",
    deprecated: true

  field :flush_all_tss, 5,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.GetFlushAllStateRequest.FlushAllTssEntry,
    json_name: "flushAllTss",
    map: true
end
