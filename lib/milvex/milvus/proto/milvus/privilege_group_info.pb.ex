defmodule Milvex.Milvus.Proto.Milvus.PrivilegeGroupInfo do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :group_name, 1, type: :string, json_name: "groupName"
  field :privileges, 2, repeated: true, type: Milvex.Milvus.Proto.Milvus.PrivilegeEntity
end
