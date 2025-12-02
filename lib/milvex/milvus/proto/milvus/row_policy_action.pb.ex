defmodule Milvex.Milvus.Proto.Milvus.RowPolicyAction do
  @moduledoc """
  Row Policy Action enum
  ===== Row Level Security (RLS) Messages =====
  """

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :Query, 0
  field :Search, 1
  field :Insert, 2
  field :Delete, 3
  field :Upsert, 4
end
