defmodule Milvex.Milvus.Proto.Milvus.DummyRequest do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :request_type, 1, type: :string, json_name: "requestType"
end
