defmodule Milvex.Milvus.Proto.Schema.FieldSchema do
  @moduledoc """
  *
  @brief Field schema
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :fieldID, 1, type: :int64
  field :name, 2, type: :string
  field :is_primary_key, 3, type: :bool, json_name: "isPrimaryKey"
  field :description, 4, type: :string

  field :data_type, 5,
    type: Milvex.Milvus.Proto.Schema.DataType,
    json_name: "dataType",
    enum: true

  field :type_params, 6,
    repeated: true,
    type: Milvex.Milvus.Proto.Common.KeyValuePair,
    json_name: "typeParams"

  field :index_params, 7,
    repeated: true,
    type: Milvex.Milvus.Proto.Common.KeyValuePair,
    json_name: "indexParams"

  field :autoID, 8, type: :bool
  field :state, 9, type: Milvex.Milvus.Proto.Schema.FieldState, enum: true

  field :element_type, 10,
    type: Milvex.Milvus.Proto.Schema.DataType,
    json_name: "elementType",
    enum: true

  field :default_value, 11, type: Milvex.Milvus.Proto.Schema.ValueField, json_name: "defaultValue"
  field :is_dynamic, 12, type: :bool, json_name: "isDynamic"
  field :is_partition_key, 13, type: :bool, json_name: "isPartitionKey"
  field :is_clustering_key, 14, type: :bool, json_name: "isClusteringKey"
  field :nullable, 15, type: :bool
  field :is_function_output, 16, type: :bool, json_name: "isFunctionOutput"
  field :external_field, 17, type: :string, json_name: "externalField"
end
