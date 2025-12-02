defmodule Milvex.Milvus.Proto.Common.PrivilegeExt do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :object_type, 1,
    type: Milvex.Milvus.Proto.Common.ObjectType,
    json_name: "objectType",
    enum: true

  field :object_privilege, 2,
    type: Milvex.Milvus.Proto.Common.ObjectPrivilege,
    json_name: "objectPrivilege",
    enum: true

  field :object_name_index, 3, type: :int32, json_name: "objectNameIndex"
  field :object_name_indexs, 4, type: :int32, json_name: "objectNameIndexs"
end
