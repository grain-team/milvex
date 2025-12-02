defmodule Milvex.Milvus.Proto.Milvus.SelectUserRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :user, 2, type: Milvex.Milvus.Proto.Milvus.UserEntity
  field :include_role_info, 3, type: :bool, json_name: "includeRoleInfo"
end
