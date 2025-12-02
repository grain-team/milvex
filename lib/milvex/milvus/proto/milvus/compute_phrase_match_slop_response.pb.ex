defmodule Milvex.Milvus.Proto.Milvus.ComputePhraseMatchSlopResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :is_match, 2, repeated: true, type: :bool, json_name: "isMatch"
  field :slops, 3, repeated: true, type: :int64
end
