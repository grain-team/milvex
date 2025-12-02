defmodule Milvex.Milvus.Proto.Schema.StructArrayFieldSchema do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :fieldID, 1, type: :int64
  field :name, 2, type: :string
  field :description, 3, type: :string
  field :fields, 4, repeated: true, type: Milvex.Milvus.Proto.Schema.FieldSchema

  field :type_params, 5,
    repeated: true,
    type: Milvex.Milvus.Proto.Common.KeyValuePair,
    json_name: "typeParams"
end
