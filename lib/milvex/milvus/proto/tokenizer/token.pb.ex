defmodule Milvex.Milvus.Proto.Tokenizer.Token do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :text, 1, type: :string
  field :offset_from, 2, type: :int32, json_name: "offsetFrom"
  field :offset_to, 3, type: :int32, json_name: "offsetTo"
  field :position, 4, type: :int32
  field :position_length, 5, type: :int32, json_name: "positionLength"
end
