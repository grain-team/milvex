defmodule Milvex.Milvus.Proto.Feder.FederSegmentSearchResult do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :segmentID, 1, type: :int64
  field :visit_info, 2, type: :string, json_name: "visitInfo"
end
