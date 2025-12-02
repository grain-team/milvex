defmodule Milvex.Milvus.Proto.Milvus.AnalyzerToken do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :token, 1, type: :string
  field :start_offset, 2, type: :int64, json_name: "startOffset"
  field :end_offset, 3, type: :int64, json_name: "endOffset"
  field :position, 4, type: :int64
  field :position_length, 5, type: :int64, json_name: "positionLength"
  field :hash, 6, type: :uint32
end
