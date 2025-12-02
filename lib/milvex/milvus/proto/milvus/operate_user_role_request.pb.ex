defmodule Milvex.Milvus.Proto.Milvus.OperateUserRoleRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :username, 2, type: :string
  field :role_name, 3, type: :string, json_name: "roleName"
  field :type, 4, type: Milvex.Milvus.Proto.Milvus.OperateUserRoleType, enum: true
end
