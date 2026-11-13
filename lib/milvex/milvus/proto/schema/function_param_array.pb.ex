defmodule Milvex.Milvus.Proto.Schema.FunctionParamArray do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :values, 1, repeated: true, type: Milvex.Milvus.Proto.Schema.FunctionParamValue
end
