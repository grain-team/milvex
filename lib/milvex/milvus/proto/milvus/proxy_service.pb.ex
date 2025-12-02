defmodule Milvex.Milvus.Proto.Milvus.ProxyService.Service do
  use GRPC.Service, name: "milvus.proto.milvus.ProxyService", protoc_gen_elixir_version: "0.15.0"

  rpc :RegisterLink,
      Milvex.Milvus.Proto.Milvus.RegisterLinkRequest,
      Milvex.Milvus.Proto.Milvus.RegisterLinkResponse
end

defmodule Milvex.Milvus.Proto.Milvus.ProxyService.Stub do
  use GRPC.Stub, service: Milvex.Milvus.Proto.Milvus.ProxyService.Service
end
