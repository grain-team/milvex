defmodule Milvex.Milvus.Proto.Milvus.FlushAllRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :db_name, 2, type: :string, json_name: "dbName", deprecated: true

  field :flush_targets, 3,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.FlushAllTarget,
    json_name: "flushTargets",
    deprecated: true
end
