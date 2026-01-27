defmodule Milvex.Milvus.Proto.Milvus.ClientHeartbeatResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :server_timestamp, 2, type: :int64, json_name: "serverTimestamp"
  field :commands, 3, repeated: true, type: Milvex.Milvus.Proto.Common.ClientCommand
end
