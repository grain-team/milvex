defmodule Milvex.Milvus.Proto.Schema.MetricValue do
  @moduledoc """
  MetricValue is the typed result of a single metric aggregation.
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :value, 0

  field :int_val, 1, type: :int64, json_name: "intVal", oneof: 0
  field :double_val, 2, type: :double, json_name: "doubleVal", oneof: 0
  field :string_val, 3, type: :string, json_name: "stringVal", oneof: 0
  field :bool_val, 4, type: :bool, json_name: "boolVal", oneof: 0
end
