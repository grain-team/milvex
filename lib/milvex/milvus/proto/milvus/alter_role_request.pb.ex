defmodule Milvex.Milvus.Proto.Milvus.AlterRoleRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :role_name, 2, type: :string, json_name: "roleName"
  field :description, 3, type: :string
end
