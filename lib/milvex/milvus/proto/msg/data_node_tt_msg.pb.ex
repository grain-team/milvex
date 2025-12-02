defmodule Milvex.Milvus.Proto.Msg.DataNodeTtMsg do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :channel_name, 2, type: :string, json_name: "channelName"
  field :timestamp, 3, type: :uint64

  field :segments_stats, 4,
    repeated: true,
    type: Milvex.Milvus.Proto.Common.SegmentStats,
    json_name: "segmentsStats"
end
