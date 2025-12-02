defmodule Milvex.Milvus.Proto.Common.SegmentState do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :SegmentStateNone, 0
  field :NotExist, 1
  field :Growing, 2
  field :Sealed, 3
  field :Flushed, 4
  field :Flushing, 5
  field :Dropped, 6
  field :Importing, 7
end
