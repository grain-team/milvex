defmodule Milvex.Milvus.Proto.Milvus.AlterCollectionSchemaRequest.Action do
  @moduledoc """
  Action to perform on the collection schema
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :op, 0

  field :add_request, 1,
    type: Milvex.Milvus.Proto.Milvus.AlterCollectionSchemaRequest.AddRequest,
    json_name: "addRequest",
    oneof: 0

  field :drop_request, 2,
    type: Milvex.Milvus.Proto.Milvus.AlterCollectionSchemaRequest.DropRequest,
    json_name: "dropRequest",
    oneof: 0
end
