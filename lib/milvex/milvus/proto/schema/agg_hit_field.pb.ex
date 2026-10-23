defmodule Milvex.Milvus.Proto.Schema.AggHitField do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :value, 0

  field :field_id, 1, type: :int64, json_name: "fieldId"
  field :field_name, 2, type: :string, json_name: "fieldName"
  field :int_val, 3, type: :int64, json_name: "intVal", oneof: 0
  field :bool_val, 4, type: :bool, json_name: "boolVal", oneof: 0
  field :float_val, 5, type: :float, json_name: "floatVal", oneof: 0
  field :double_val, 6, type: :double, json_name: "doubleVal", oneof: 0
  field :string_val, 7, type: :string, json_name: "stringVal", oneof: 0
  field :bytes_val, 8, type: :bytes, json_name: "bytesVal", oneof: 0
end
