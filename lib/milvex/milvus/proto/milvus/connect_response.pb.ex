defmodule Milvex.Milvus.Proto.Milvus.ConnectResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :server_info, 2, type: Milvex.Milvus.Proto.Common.ServerInfo, json_name: "serverInfo"
  field :identifier, 3, type: :int64
end
