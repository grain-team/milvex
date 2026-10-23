defmodule Milvex.Milvus.Proto.Common.TopHitsSpec do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :size, 1, type: :int64
  field :sort, 2, repeated: true, type: Milvex.Milvus.Proto.Common.SortSpec
end
