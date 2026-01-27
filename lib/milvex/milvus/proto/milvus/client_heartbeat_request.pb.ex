defmodule Milvex.Milvus.Proto.Milvus.ClientHeartbeatRequest do
  @moduledoc """
  Client Heartbeat
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :client_info, 1, type: Milvex.Milvus.Proto.Common.ClientInfo, json_name: "clientInfo"
  field :report_timestamp, 2, type: :int64, json_name: "reportTimestamp"
  field :metrics, 3, repeated: true, type: Milvex.Milvus.Proto.Common.OperationMetrics

  field :command_replies, 4,
    repeated: true,
    type: Milvex.Milvus.Proto.Common.CommandReply,
    json_name: "commandReplies"

  field :config_hash, 5, type: :string, json_name: "configHash"
  field :last_command_timestamp, 6, type: :int64, json_name: "lastCommandTimestamp"
end
