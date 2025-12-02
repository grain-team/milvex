defmodule Milvex.Milvus.Proto.Milvus.OperatePrivilegeV2Request do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :role, 2, type: Milvex.Milvus.Proto.Milvus.RoleEntity
  field :grantor, 3, type: Milvex.Milvus.Proto.Milvus.GrantorEntity
  field :type, 4, type: Milvex.Milvus.Proto.Milvus.OperatePrivilegeType, enum: true
  field :db_name, 5, type: :string, json_name: "dbName"
  field :collection_name, 6, type: :string, json_name: "collectionName"
end
