defmodule Milvex.Milvus.Proto.Milvus.DeleteClientCommandResponse do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
end
