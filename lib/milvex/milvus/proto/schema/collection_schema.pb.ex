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
  field :external_source, 11, type: :string, json_name: "externalSource"
  field :external_spec, 12, type: :string, json_name: "externalSpec"
  field :do_physical_backfill, 13, type: :bool, json_name: "doPhysicalBackfill"
  field :file_resource_ids, 14, repeated: true, type: :int64, json_name: "fileResourceIds"
  field :enable_namespace, 15, type: :bool, json_name: "enableNamespace"
end
