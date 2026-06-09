defmodule Milvex.Milvus.Proto.Schema.CollectionSchema do
  @moduledoc """
  *
  @brief Collection schema
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :name, 1, type: :string
  field :description, 2, type: :string
  field :autoID, 3, type: :bool, deprecated: true
  field :fields, 4, repeated: true, type: Milvex.Milvus.Proto.Schema.FieldSchema
  field :enable_dynamic_field, 5, type: :bool, json_name: "enableDynamicField"
  field :properties, 6, repeated: true, type: Milvex.Milvus.Proto.Common.KeyValuePair
  field :functions, 7, repeated: true, type: Milvex.Milvus.Proto.Schema.FunctionSchema
  field :dbName, 8, type: :string

  field :struct_array_fields, 9,
    repeated: true,
    type: Milvex.Milvus.Proto.Schema.StructArrayFieldSchema,
    json_name: "structArrayFields"

  field :version, 10, type: :int32
  field :enable_namespace, 15, type: :bool, json_name: "enableNamespace"
end
