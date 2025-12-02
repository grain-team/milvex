defmodule Milvex.Milvus.Proto.Milvus.UserResult do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :user, 1, type: Milvex.Milvus.Proto.Milvus.UserEntity
  field :roles, 2, repeated: true, type: Milvex.Milvus.Proto.Milvus.RoleEntity
end
