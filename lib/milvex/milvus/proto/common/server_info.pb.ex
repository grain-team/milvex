defmodule Milvex.Milvus.Proto.Common.ServerInfo do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :build_tags, 1, type: :string, json_name: "buildTags"
  field :build_time, 2, type: :string, json_name: "buildTime"
  field :git_commit, 3, type: :string, json_name: "gitCommit"
  field :go_version, 4, type: :string, json_name: "goVersion"
  field :deploy_mode, 5, type: :string, json_name: "deployMode"

  field :reserved, 6,
    repeated: true,
    type: Milvex.Milvus.Proto.Common.ServerInfo.ReservedEntry,
    map: true
end
