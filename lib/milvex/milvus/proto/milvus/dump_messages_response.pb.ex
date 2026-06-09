defmodule Milvex.Milvus.Proto.Milvus.DumpMessagesResponse do
  @moduledoc """
  DumpMessagesResponse streams messages from the WAL.
  Each response contains either an error status or a message (never both).
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :response, 0

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status, oneof: 0
  field :message, 2, type: Milvex.Milvus.Proto.Common.ImmutableMessage, oneof: 0
end
