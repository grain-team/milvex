defmodule Milvex.Milvus.Proto.Milvus.Hits do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :IDs, 1, repeated: true, type: :int64
  field :row_data, 2, repeated: true, type: :bytes, json_name: "rowData"
  field :scores, 3, repeated: true, type: :float
end
