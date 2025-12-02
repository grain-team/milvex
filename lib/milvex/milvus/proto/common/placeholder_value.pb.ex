defmodule Milvex.Milvus.Proto.Common.PlaceholderValue do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :tag, 1, type: :string
  field :type, 2, type: Milvex.Milvus.Proto.Common.PlaceholderType, enum: true
  field :values, 3, repeated: true, type: :bytes
  field :element_level, 4, type: :bool, json_name: "elementLevel"
end
