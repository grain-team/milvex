defmodule Milvex.Milvus.Proto.Common.StateCode do
  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :Initializing, 0
  field :Healthy, 1
  field :Abnormal, 2
  field :StandBy, 3
  field :Stopping, 4
end
