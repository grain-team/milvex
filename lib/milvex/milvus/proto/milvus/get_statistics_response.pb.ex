defmodule Milvex.Milvus.Proto.Milvus.GetStatisticsResponse do
  @moduledoc """
  *
  Will return statistics in stats field like [{key:"row_count",value:"1"}]
  WARNING: This API is experimental and not useful for now.
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :status, 1, type: Milvex.Milvus.Proto.Common.Status
  field :stats, 2, repeated: true, type: Milvex.Milvus.Proto.Common.KeyValuePair
end
