defmodule Milvex.Milvus.Proto.Schema.VectorClusteringInfo do
  @moduledoc """
  vector field clustering info
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :field, 1, type: :string
  field :centroid, 2, type: Milvex.Milvus.Proto.Schema.VectorField
end
