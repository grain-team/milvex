defmodule Milvex.Milvus.Proto.Milvus.CalcDistanceResults do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :array, 0

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :int_dist, 2, type: Milvex.Milvus.Proto.Schema.IntArray, json_name: "intDist", oneof: 0

  field :float_dist, 3,
    type: Milvex.Milvus.Proto.Schema.FloatArray,
    json_name: "floatDist",
    oneof: 0
end
