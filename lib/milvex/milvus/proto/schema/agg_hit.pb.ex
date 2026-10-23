defmodule Milvex.Milvus.Proto.Schema.AggHit do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :pk, 0

  field :int_pk, 1, type: :int64, json_name: "intPk", oneof: 0
  field :str_pk, 2, type: :string, json_name: "strPk", oneof: 0
  field :score, 3, type: :float
  field :fields, 4, repeated: true, type: Milvex.Milvus.Proto.Schema.AggHitField
end
