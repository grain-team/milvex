defmodule Milvex.Milvus.Proto.Milvus.RBACMeta do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :users, 1, repeated: true, type: Milvex.Milvus.Proto.Milvus.UserInfo
  field :roles, 2, repeated: true, type: Milvex.Milvus.Proto.Milvus.RoleEntity
  field :grants, 3, repeated: true, type: Milvex.Milvus.Proto.Milvus.GrantEntity

  field :privilege_groups, 4,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.PrivilegeGroupInfo,
    json_name: "privilegeGroups"
end
