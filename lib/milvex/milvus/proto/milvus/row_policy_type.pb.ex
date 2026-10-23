defmodule Milvex.Milvus.Proto.Milvus.RowPolicyType do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :RowPolicyTypeUnknown, 0
  field :RowPolicyTypePermissive, 1
  field :RowPolicyTypeRestrictive, 2
end
