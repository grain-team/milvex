defmodule Milvex.Milvus.Proto.Common.LoadState do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :LoadStateNotExist, 0
  field :LoadStateNotLoad, 1
  field :LoadStateLoading, 2
  field :LoadStateLoaded, 3
end
