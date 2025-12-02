defmodule Milvex.Milvus.Proto.Milvus.ShardReplica do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :leaderID, 1, type: :int64
  field :leader_addr, 2, type: :string, json_name: "leaderAddr"
  field :dm_channel_name, 3, type: :string, json_name: "dmChannelName"
  field :node_ids, 4, repeated: true, type: :int64, json_name: "nodeIds"
end
