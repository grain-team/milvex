defmodule Milvex.Milvus.Proto.Milvus.CreateCredentialRequest do
  @moduledoc """
  https://wiki.lfaidata.foundation/display/MIL/MEP+27+--+Support+Basic+Authentication
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :username, 2, type: :string
  field :password, 3, type: :string
  field :created_utc_timestamps, 4, type: :uint64, json_name: "createdUtcTimestamps"
  field :modified_utc_timestamps, 5, type: :uint64, json_name: "modifiedUtcTimestamps"
end
