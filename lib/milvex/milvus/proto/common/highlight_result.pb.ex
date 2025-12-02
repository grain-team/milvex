defmodule Milvex.Milvus.Proto.Common.HighlightResult do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :field_name, 1, type: :string, json_name: "fieldName"
  field :datas, 2, repeated: true, type: Milvex.Milvus.Proto.Common.HighlightData
end
