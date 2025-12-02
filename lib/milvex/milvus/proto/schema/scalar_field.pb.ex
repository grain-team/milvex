defmodule Milvex.Milvus.Proto.Schema.ScalarField do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :data, 0

  field :bool_data, 1, type: Milvex.Milvus.Proto.Schema.BoolArray, json_name: "boolData", oneof: 0
  field :int_data, 2, type: Milvex.Milvus.Proto.Schema.IntArray, json_name: "intData", oneof: 0
  field :long_data, 3, type: Milvex.Milvus.Proto.Schema.LongArray, json_name: "longData", oneof: 0

  field :float_data, 4,
    type: Milvex.Milvus.Proto.Schema.FloatArray,
    json_name: "floatData",
    oneof: 0

  field :double_data, 5,
    type: Milvex.Milvus.Proto.Schema.DoubleArray,
    json_name: "doubleData",
    oneof: 0

  field :string_data, 6,
    type: Milvex.Milvus.Proto.Schema.StringArray,
    json_name: "stringData",
    oneof: 0

  field :bytes_data, 7,
    type: Milvex.Milvus.Proto.Schema.BytesArray,
    json_name: "bytesData",
    oneof: 0

  field :array_data, 8,
    type: Milvex.Milvus.Proto.Schema.ArrayArray,
    json_name: "arrayData",
    oneof: 0

  field :json_data, 9, type: Milvex.Milvus.Proto.Schema.JSONArray, json_name: "jsonData", oneof: 0

  field :geometry_data, 10,
    type: Milvex.Milvus.Proto.Schema.GeometryArray,
    json_name: "geometryData",
    oneof: 0

  field :timestamptz_data, 11,
    type: Milvex.Milvus.Proto.Schema.TimestamptzArray,
    json_name: "timestamptzData",
    oneof: 0

  field :geometry_wkt_data, 12,
    type: Milvex.Milvus.Proto.Schema.GeometryWktArray,
    json_name: "geometryWktData",
    oneof: 0
end
