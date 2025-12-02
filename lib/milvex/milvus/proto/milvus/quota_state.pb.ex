defmodule Milvex.Milvus.Proto.Milvus.QuotaState do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :Unknown, 0
  field :ReadLimited, 2
  field :WriteLimited, 3
  field :DenyToRead, 4
  field :DenyToWrite, 5
  field :DenyToDDL, 6
end
