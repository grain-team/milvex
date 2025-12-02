defmodule Milvex.Milvus.Proto.Common.PbExtension do
  use Protobuf, protoc_gen_elixir_version: "0.15.0"

  extend Google.Protobuf.MessageOptions, :privilege_ext_obj, 1001,
    optional: true,
    type: Milvex.Milvus.Proto.Common.PrivilegeExt,
    json_name: "privilegeExtObj"
end
