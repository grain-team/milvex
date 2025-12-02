defmodule Milvex.Milvus.Proto.Milvus.PrivilegeLevel do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :Cluster, 0
  field :Database, 1
  field :Collection, 2
end
