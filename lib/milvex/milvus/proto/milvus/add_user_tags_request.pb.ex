defmodule Milvex.Milvus.Proto.Milvus.AddUserTagsRequest do
  @moduledoc """
  User Tag Management
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :user_name, 2, type: :string, json_name: "userName"

  field :tags, 3,
    repeated: true,
    type: Milvex.Milvus.Proto.Milvus.AddUserTagsRequest.TagsEntry,
    map: true
end
