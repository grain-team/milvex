defmodule Milvex.Milvus.Proto.Milvus.OperatePrivilegeType do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :Grant, 0
  field :Revoke, 1
end
