defmodule Milvex.Milvus.Proto.Milvus.BatchUpdateManifestItem do
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :segment_id, 1, type: :int64, json_name: "segmentId"
  field :manifest_version, 2, type: :int64, json_name: "manifestVersion"
end
