defmodule Milvex.Milvus.Proto.Common.MetricAggSpec do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :op, 1, type: :string
  field :field_name, 2, type: :string, json_name: "fieldName"
end
