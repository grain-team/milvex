defmodule Milvex.Milvus.Proto.Milvus.ClientTelemetry do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :client_info, 1, type: Milvex.Milvus.Proto.Common.ClientInfo, json_name: "clientInfo"
  field :last_heartbeat_time, 2, type: :int64, json_name: "lastHeartbeatTime"
  field :status, 3, type: :string
  field :databases, 4, repeated: true, type: :string
  field :metrics, 5, repeated: true, type: Milvex.Milvus.Proto.Common.OperationMetrics
end
