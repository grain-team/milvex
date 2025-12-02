defmodule Milvex.Milvus.Proto.Tokenizer.Tokenizer.Service do
  use GRPC.Service, name: "milvus.proto.tokenizer.Tokenizer", protoc_gen_elixir_version: "0.15.0"

  rpc :Tokenize,
      Milvex.Milvus.Proto.Tokenizer.TokenizationRequest,
      Milvex.Milvus.Proto.Tokenizer.TokenizationResponse
end

defmodule Milvex.Milvus.Proto.Tokenizer.Tokenizer.Stub do
  use GRPC.Stub, service: Milvex.Milvus.Proto.Tokenizer.Tokenizer.Service
end
