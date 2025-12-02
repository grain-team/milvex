defmodule Milvex.Milvus.Proto.Milvus.SelectRoleRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :role, 2, type: Milvex.Milvus.Proto.Milvus.RoleEntity
  field :include_user_info, 3, type: :bool, json_name: "includeUserInfo"
end
