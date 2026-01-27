defmodule Milvex.Milvus.Proto.Common.CommandReply do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :command_id, 1, type: :string, json_name: "commandId"
  field :success, 2, type: :bool
  field :error_message, 3, type: :string, json_name: "errorMessage"
  field :payload, 4, type: :bytes
end
