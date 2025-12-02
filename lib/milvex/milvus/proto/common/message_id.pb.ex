defmodule Milvex.Milvus.Proto.Common.MessageID do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :id, 1, type: :string
  field :WAL_name, 2, type: Milvex.Milvus.Proto.Common.WALName, json_name: "WALName", enum: true
end
