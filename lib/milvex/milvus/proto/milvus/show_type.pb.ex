defmodule Milvex.Milvus.Proto.Milvus.ShowType do
  @moduledoc """
  Deprecated: use GetLoadingProgress rpc instead
  This is for ShowCollectionsRequest type field.
  """

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :All, 0
  field :InMemory, 1
end
