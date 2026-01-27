defmodule Milvex.Milvus.Proto.Milvus.DeleteClientCommandRequest do
  @moduledoc """
  Delete Client Command
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :command_id, 1, type: :string, json_name: "commandId"
end
