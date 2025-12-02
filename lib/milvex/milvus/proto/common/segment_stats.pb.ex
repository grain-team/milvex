defmodule Milvex.Milvus.Proto.Common.SegmentStats do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :SegmentID, 1, type: :int64
  field :NumRows, 2, type: :int64
end
