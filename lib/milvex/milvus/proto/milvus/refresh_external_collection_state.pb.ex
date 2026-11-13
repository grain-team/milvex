defmodule Milvex.Milvus.Proto.Milvus.RefreshExternalCollectionState do
  @moduledoc """
  External Collection Refresh APIs
  """

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :RefreshPending, 0
  field :RefreshInProgress, 1
  field :RefreshCompleted, 2
  field :RefreshFailed, 3
end
