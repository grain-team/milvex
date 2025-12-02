defmodule Milvex.Milvus.Proto.Common.ConnectionParam do
  @moduledoc """
  ConnectionParam defines the params to connect to the Milvus cluster.
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :uri, 1, type: :string
  field :token, 2, type: :string
end
