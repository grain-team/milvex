defmodule Milvex.Milvus.Proto.Schema.FieldData do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :field, 0

  field :type, 1, type: Milvex.Milvus.Proto.Schema.DataType, enum: true
  field :field_name, 2, type: :string, json_name: "fieldName"
  field :scalars, 3, type: Milvex.Milvus.Proto.Schema.ScalarField, oneof: 0
  field :vectors, 4, type: Milvex.Milvus.Proto.Schema.VectorField, oneof: 0

  field :struct_arrays, 8,
    type: Milvex.Milvus.Proto.Schema.StructArrayField,
    json_name: "structArrays",
    oneof: 0

  field :field_id, 5, type: :int64, json_name: "fieldId"
  field :is_dynamic, 6, type: :bool, json_name: "isDynamic"
  field :valid_data, 7, repeated: true, type: :bool, json_name: "validData"
end
