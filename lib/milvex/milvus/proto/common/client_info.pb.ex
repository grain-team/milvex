defmodule Milvex.Milvus.Proto.Common.ClientInfo do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :sdk_type, 1, type: :string, json_name: "sdkType"
  field :sdk_version, 2, type: :string, json_name: "sdkVersion"
  field :local_time, 3, type: :string, json_name: "localTime"
  field :user, 4, type: :string
  field :host, 5, type: :string

  field :reserved, 6,
    repeated: true,
    type: Milvex.Milvus.Proto.Common.ClientInfo.ReservedEntry,
    map: true
end
