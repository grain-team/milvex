defmodule Milvex.Milvus.Proto.Milvus.RoleEntity do
  @moduledoc """
  https://wiki.lfaidata.foundation/display/MIL/MEP+29+--+Support+Role-Based+Access+Control
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :name, 1, type: :string
end
