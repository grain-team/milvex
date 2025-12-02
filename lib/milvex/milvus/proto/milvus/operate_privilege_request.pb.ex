defmodule Milvex.Milvus.Proto.Milvus.OperatePrivilegeRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :entity, 2, type: Milvex.Milvus.Proto.Milvus.GrantEntity
  field :type, 3, type: Milvex.Milvus.Proto.Milvus.OperatePrivilegeType, enum: true
  field :version, 4, type: :string
end
