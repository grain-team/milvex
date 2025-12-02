defmodule Milvex.Milvus.Proto.Milvus.FlushCollectionResult do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :collection_name, 1, type: :string, json_name: "collectionName"
  field :segment_ids, 2, type: Milvex.Milvus.Proto.Schema.LongArray, json_name: "segmentIds"

  field :flush_segment_ids, 3,
    type: Milvex.Milvus.Proto.Schema.LongArray,
    json_name: "flushSegmentIds"

  field :seal_time, 4, type: :int64, json_name: "sealTime"
  field :flush_ts, 5, type: :uint64, json_name: "flushTs"

  field :channel_cps, 6,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.FlushCollectionResult.ChannelCpsEntry,
    json_name: "channelCps",
    map: true
end
