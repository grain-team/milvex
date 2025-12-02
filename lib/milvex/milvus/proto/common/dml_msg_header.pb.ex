defmodule Milvex.Milvus.Proto.Common.DMLMsgHeader do
  @moduledoc """
  Don't Modify This. @czs
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :base, 1, type: Milvex.Milvus.Proto.Common.MsgBase
  field :shardName, 2, type: :string
end
