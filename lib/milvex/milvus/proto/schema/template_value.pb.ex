defmodule Milvex.Milvus.Proto.Schema.TemplateValue do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :val, 0

  field :bool_val, 1, type: :bool, json_name: "boolVal", oneof: 0
  field :int64_val, 2, type: :int64, json_name: "int64Val", oneof: 0
  field :float_val, 3, type: :double, json_name: "floatVal", oneof: 0
  field :string_val, 4, type: :string, json_name: "stringVal", oneof: 0

  field :array_val, 5,
    type: Milvex.Milvus.Proto.Schema.TemplateArrayValue,
    json_name: "arrayVal",
    oneof: 0
end
