defmodule Milvex.Milvus.Proto.Milvus.GetMetricsResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :response, 2, type: :string
  field :component_name, 3, type: :string, json_name: "componentName"
end
