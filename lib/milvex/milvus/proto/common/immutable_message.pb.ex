defmodule Milvex.Milvus.Proto.Common.ImmutableMessage do
  @moduledoc """
  ImmutableMessage is the message that can not be modified anymore.
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :id, 1, type: Milvex.Milvus.Proto.Common.MessageID
  field :payload, 2, type: :bytes

  field :properties, 3,
    repeated: true,
    type: Milvex.Milvus.Proto.Common.ImmutableMessage.PropertiesEntry,
    map: true
end
