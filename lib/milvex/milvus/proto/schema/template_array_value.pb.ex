defmodule Milvex.Milvus.Proto.Schema.TemplateArrayValue do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :data, 0

  field :bool_data, 1, type: Milvex.Milvus.Proto.Schema.BoolArray, json_name: "boolData", oneof: 0
  field :long_data, 2, type: Milvex.Milvus.Proto.Schema.LongArray, json_name: "longData", oneof: 0

  field :double_data, 3,
    type: Milvex.Milvus.Proto.Schema.DoubleArray,
    json_name: "doubleData",
    oneof: 0

  field :string_data, 4,
    type: Milvex.Milvus.Proto.Schema.StringArray,
    json_name: "stringData",
    oneof: 0

  field :array_data, 5,
    type: Milvex.Milvus.Proto.Schema.TemplateArrayValueArray,
    json_name: "arrayData",
    oneof: 0

  field :json_data, 6, type: Milvex.Milvus.Proto.Schema.JSONArray, json_name: "jsonData", oneof: 0
end
