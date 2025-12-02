defmodule Milvex.Milvus.Proto.Milvus.FlushResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :db_name, 2, type: :string, json_name: "dbName"

  field :coll_segIDs, 3,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.FlushResponse.CollSegIDsEntry,
    json_name: "collSegIDs",
    map: true

  field :flush_coll_segIDs, 4,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.FlushResponse.FlushCollSegIDsEntry,
    json_name: "flushCollSegIDs",
    map: true

  field :coll_seal_times, 5,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.FlushResponse.CollSealTimesEntry,
    json_name: "collSealTimes",
    map: true

  field :coll_flush_ts, 6,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.FlushResponse.CollFlushTsEntry,
    json_name: "collFlushTs",
    map: true

  field :channel_cps, 7,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.FlushResponse.ChannelCpsEntry,
    json_name: "channelCps",
    map: true
end
