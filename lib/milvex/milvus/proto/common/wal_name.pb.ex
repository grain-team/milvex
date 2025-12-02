defmodule Milvex.Milvus.Proto.Common.WALName do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :Unknown, 0
  field :RocksMQ, 1
  field :Pulsar, 2
  field :Kafka, 3
  field :WoodPecker, 4
  field :Test, 999
end
