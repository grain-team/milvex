defmodule Milvex.Milvus.Proto.Schema.ScalarClusteringInfo do
  @moduledoc """
  Scalar field clustering info
  todo more definitions: min/max, etc
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :field, 1, type: :string
end
