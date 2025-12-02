# Milvex

An Elixir client for the Milvus vector database, enabling seamless integration and management of vector data.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `milvex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:milvex, "~> 0.1.0"}
  ]
end
```

## Generating the Elixir API Client from Protobuf Definitions

From the milvus-proto/proto directory, run the following command to generate:

```bash
protoc --elixir_out=one_file_per_module=true,plugins=grpc:../../lib --elixir_opt=package_prefix=milvex --elixir_opt=include_docs=true *.proto
```



Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/milvex>.

