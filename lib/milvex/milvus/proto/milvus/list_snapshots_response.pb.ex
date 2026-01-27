defmodule Milvex.Milvus.Proto.Milvus.ListSnapshotsResponse do
  @moduledoc """
  return all snapshots for the given collection
  Note: list snapshots is not a privilege check operation
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :snapshots, 2, repeated: true, type: :string
end
