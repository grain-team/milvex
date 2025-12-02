defmodule Milvex.Milvus.Proto.Milvus.UserInfo do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :user, 1, type: :string
  field :password, 2, type: :string
  field :roles, 3, repeated: true, type: Milvex.Milvus.Proto.Milvus.RoleEntity
end
