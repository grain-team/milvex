defmodule Milvex.Milvus.Proto.Common.SortSpec do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :field_name, 1, type: :string, json_name: "fieldName"
  field :direction, 2, type: :string
  field :null_first, 3, type: :bool, json_name: "nullFirst"
end
