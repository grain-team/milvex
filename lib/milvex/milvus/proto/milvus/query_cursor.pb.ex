defmodule Milvex.Milvus.Proto.Milvus.QueryCursor do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :cursor_pk, 0

  field :session_ts, 1, type: :uint64, json_name: "sessionTs"
  field :str_pk, 2, type: :string, json_name: "strPk", oneof: 0
  field :int_pk, 3, type: :int64, json_name: "intPk", oneof: 0
end
