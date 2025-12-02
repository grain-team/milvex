defmodule Milvex.Milvus.Proto.Msg.InsertDataVersion do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :RowBased, 0
  field :ColumnBased, 1
end
