defmodule Milvex.Milvus.Proto.Schema.FunctionParamValue do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :value, 0

  field :bool_value, 1, type: :bool, json_name: "boolValue", oneof: 0
  field :int64_value, 2, type: :int64, json_name: "int64Value", oneof: 0
  field :double_value, 3, type: :double, json_name: "doubleValue", oneof: 0
  field :string_value, 4, type: :string, json_name: "stringValue", oneof: 0

  field :array_value, 5,
    type: Milvex.Milvus.Proto.Schema.FunctionParamArray,
    json_name: "arrayValue",
    oneof: 0

  field :object_value, 6,
    type: Milvex.Milvus.Proto.Schema.FunctionParamObject,
    json_name: "objectValue",
    oneof: 0

  field :bytes_value, 7, type: :bytes, json_name: "bytesValue", oneof: 0
end
