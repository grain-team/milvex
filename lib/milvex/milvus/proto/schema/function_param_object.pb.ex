defmodule Milvex.Milvus.Proto.Schema.FunctionParamObject do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :fields, 1,
    repeated: true,
    type: Milvex.Milvus.Proto.Schema.FunctionParamObject.FieldsEntry,
    map: true
end
