defmodule Milvex.Milvus.Proto.Milvus.GrantEntity do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :role, 1, type: Milvex.Milvus.Proto.Milvus.RoleEntity
  field :object, 2, type: Milvex.Milvus.Proto.Milvus.ObjectEntity
  field :object_name, 3, type: :string, json_name: "objectName"
  field :grantor, 4, type: Milvex.Milvus.Proto.Milvus.GrantorEntity
  field :db_name, 5, type: :string, json_name: "dbName"
end
