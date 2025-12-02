defmodule Milvex.Milvus.Proto.Schema.IDs do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :id_field, 0

  field :int_id, 1, type: Milvex.Milvus.Proto.Schema.LongArray, json_name: "intId", oneof: 0
  field :str_id, 2, type: Milvex.Milvus.Proto.Schema.StringArray, json_name: "strId", oneof: 0
end
