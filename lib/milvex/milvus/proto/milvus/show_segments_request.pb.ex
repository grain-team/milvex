defmodule Milvex.Milvus.Proto.Milvus.ShowSegmentsRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :collectionID, 2, type: :int64
  field :partitionID, 3, type: :int64
end
