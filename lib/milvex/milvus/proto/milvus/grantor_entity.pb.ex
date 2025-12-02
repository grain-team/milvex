defmodule Milvex.Milvus.Proto.Milvus.GrantorEntity do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :user, 1, type: Milvex.Milvus.Proto.Milvus.UserEntity
  field :privilege, 2, type: Milvex.Milvus.Proto.Milvus.PrivilegeEntity
end
