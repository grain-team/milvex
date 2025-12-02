defmodule Milvex.Milvus.Proto.Schema.FunctionScore do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :functions, 1, repeated: true, type: Milvex.Milvus.Proto.Schema.FunctionSchema
  field :params, 2, repeated: true, type: Milvex.Milvus.Proto.Common.KeyValuePair
end
