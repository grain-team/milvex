defmodule Milvex.Milvus.Proto.Common.IndexState do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :IndexStateNone, 0
  field :Unissued, 1
  field :InProgress, 2
  field :Finished, 3
  field :Failed, 4
  field :Retry, 5
end
