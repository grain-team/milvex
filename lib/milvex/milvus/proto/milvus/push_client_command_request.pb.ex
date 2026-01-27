defmodule Milvex.Milvus.Proto.Milvus.PushClientCommandRequest do
  @moduledoc """
  Push Client Command
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :command_type, 1, type: :string, json_name: "commandType"
  field :payload, 2, type: :bytes
  field :target_client_id, 3, type: :string, json_name: "targetClientId"
  field :target_database, 4, type: :string, json_name: "targetDatabase"
  field :ttl_seconds, 5, type: :int64, json_name: "ttlSeconds"
  field :persistent, 6, type: :bool
end
