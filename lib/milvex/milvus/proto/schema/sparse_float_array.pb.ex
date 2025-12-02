defmodule Milvex.Milvus.Proto.Schema.SparseFloatArray do
  @moduledoc """
  beta, api may change
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :contents, 1, repeated: true, type: :bytes
  field :dim, 2, type: :int64
end
