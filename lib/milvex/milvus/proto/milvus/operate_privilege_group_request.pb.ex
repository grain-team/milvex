defmodule Milvex.Milvus.Proto.Milvus.OperatePrivilegeGroupRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :group_name, 2, type: :string, json_name: "groupName"
  field :privileges, 3, repeated: true, type: Milvex.Milvus.Proto.Milvus.PrivilegeEntity
  field :type, 4, type: Milvex.Milvus.Proto.Milvus.OperatePrivilegeGroupType, enum: true
end
