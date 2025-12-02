defmodule Milvex.Milvus.Proto.Schema.ValueField do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :data, 0

  field :bool_data, 1, type: :bool, json_name: "boolData", oneof: 0
  field :int_data, 2, type: :int32, json_name: "intData", oneof: 0
  field :long_data, 3, type: :int64, json_name: "longData", oneof: 0
  field :float_data, 4, type: :float, json_name: "floatData", oneof: 0
  field :double_data, 5, type: :double, json_name: "doubleData", oneof: 0
  field :string_data, 6, type: :string, json_name: "stringData", oneof: 0
  field :bytes_data, 7, type: :bytes, json_name: "bytesData", oneof: 0
  field :timestamptz_data, 8, type: :int64, json_name: "timestamptzData", oneof: 0
end
