defmodule Milvex.Milvus.Proto.Milvus.CompactionMergeInfo do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :sources, 1, repeated: true, type: :int64
  field :target, 2, type: :int64
end
