defmodule Milvex.Milvus.Proto.Milvus.OperatePrivilegeGroupType do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :AddPrivilegesToGroup, 0
  field :RemovePrivilegesFromGroup, 1
end
