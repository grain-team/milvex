defmodule Milvex.Milvus.Proto.Milvus.ComponentInfo do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :nodeID, 1, type: :int64
  field :role, 2, type: :string

  field :state_code, 3,
    type: Milvex.Milvus.Proto.Common.StateCode,
    json_name: "stateCode",
    enum: true

  field :extra_info, 4,
    repeated: true,
    type: Milvex.Milvus.Proto.Common.KeyValuePair,
    json_name: "extraInfo"
end
