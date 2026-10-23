defmodule Milvex.Milvus.Proto.Schema.BytesArray do
  @moduledoc """
  General-purpose byte-string array.
  Used for: Decimal (big-endian unscaled integer, 8 or 16 bytes per element),
  and other variable-width binary fields such as Array and raw binary blobs.
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :data, 1, repeated: true, type: :bytes
end
