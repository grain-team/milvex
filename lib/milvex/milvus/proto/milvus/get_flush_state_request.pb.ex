defmodule Milvex.Milvus.Proto.Milvus.GetFlushStateRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :segmentIDs, 1, repeated: true, type: :int64
  field :flush_ts, 2, type: :uint64, json_name: "flushTs"
  field :db_name, 3, type: :string, json_name: "dbName"
  field :collection_name, 4, type: :string, json_name: "collectionName"
end
