defmodule Milvex.Milvus.Proto.Milvus.OperateUserRoleType do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :AddUserToRole, 0
  field :RemoveUserFromRole, 1
end
