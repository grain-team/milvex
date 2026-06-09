defmodule Milvex.Milvus.Proto.Milvus.DumpMessagesRequest do
  @moduledoc """
  DumpMessagesRequest is used to dump messages from a WAL range for data salvage.

  Usage: After force failover, use GetReplicateInfo to get the salvage_checkpoint,
  then call DumpMessages with the checkpoint's message_id and timetick to retrieve
  unsynchronized messages from the old primary cluster.
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :pchannel, 1, type: :string

  field :start_message_id, 2,
    type: Milvex.Milvus.Proto.Common.MessageID,
    json_name: "startMessageId"

  field :start_timetick, 3, type: :uint64, json_name: "startTimetick"
  field :end_timetick, 4, type: :uint64, json_name: "endTimetick"
end
