defmodule Milvex.Milvus.Proto.Milvus.ReplicateConfirmedMessageInfo do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :confirmed_time_tick, 1, type: :uint64, json_name: "confirmedTimeTick"
end
