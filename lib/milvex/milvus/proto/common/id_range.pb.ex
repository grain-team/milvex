defmodule Milvex.Milvus.Proto.Common.IDRange do
  @moduledoc """
  IDRange is a half-open range of int64 ids [begin, end).
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :begin, 1, type: :int64
  field :end, 2, type: :int64
end
