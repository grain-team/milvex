defmodule Milvex.Milvus.Proto.Milvus.ConnectRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :client_info, 2, type: Milvex.Milvus.Proto.Common.ClientInfo, json_name: "clientInfo"
end
