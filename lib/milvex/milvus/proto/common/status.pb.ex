defmodule Milvex.Milvus.Proto.Common.Status do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :error_code, 1,
    type: Milvex.Milvus.Proto.Common.ErrorCode,
    json_name: "errorCode",
    enum: true,
    deprecated: true

  field :reason, 2, type: :string
  field :code, 3, type: :int32
  field :retriable, 4, type: :bool
  field :detail, 5, type: :string

  field :extra_info, 6,
    repeated: true,
    type: Milvex.Milvus.Proto.Common.Status.ExtraInfoEntry,
    json_name: "extraInfo",
    map: true
end
