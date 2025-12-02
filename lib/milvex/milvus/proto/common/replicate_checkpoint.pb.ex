defmodule Milvex.Milvus.Proto.Common.ReplicateCheckpoint do
  @moduledoc """
  ReplicateCheckpoint is the WAL replicate checkpoint of source cluster.
  It will be persisted in the target cluster metadata.
  When a replication started, we will get the replicate checkpoint from target cluster metadata.
  And use it to continue the replication at source cluster.
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :cluster_id, 1, type: :string, json_name: "clusterId"
  field :pchannel, 2, type: :string
  field :message_id, 3, type: Milvex.Milvus.Proto.Common.MessageID, json_name: "messageId"
  field :time_tick, 4, type: :uint64, json_name: "timeTick"
end
