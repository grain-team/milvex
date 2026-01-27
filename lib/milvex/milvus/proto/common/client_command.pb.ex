defmodule Milvex.Milvus.Proto.Common.ClientCommand do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :command_id, 1, type: :string, json_name: "commandId"
  field :command_type, 2, type: :string, json_name: "commandType"
  field :payload, 3, type: :bytes
  field :create_time, 4, type: :int64, json_name: "createTime"
  field :persistent, 5, type: :bool
  field :target_scope, 6, type: :string, json_name: "targetScope"
end
