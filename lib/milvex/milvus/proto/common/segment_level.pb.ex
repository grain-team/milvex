defmodule Milvex.Milvus.Proto.Common.SegmentLevel do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :Legacy, 0
  field :L0, 1
  field :L1, 2
  field :L2, 3
end
