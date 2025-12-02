defmodule Milvex.Milvus.Proto.Milvus.SelectGrantRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :entity, 2, type: Milvex.Milvus.Proto.Milvus.GrantEntity
end
