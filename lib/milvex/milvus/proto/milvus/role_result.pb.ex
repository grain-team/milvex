defmodule Milvex.Milvus.Proto.Milvus.RoleResult do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :role, 1, type: Milvex.Milvus.Proto.Milvus.RoleEntity
  field :users, 2, repeated: true, type: Milvex.Milvus.Proto.Milvus.UserEntity
end
