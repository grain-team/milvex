defmodule Milvex.Milvus.Proto.Milvus.RegisterLinkResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :address, 1, type: Milvex.Milvus.Proto.Common.Address
  field :status, 2, type: Milvex.Milvus.Proto.Common.Status
end
