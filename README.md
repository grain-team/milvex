# Milvex

An Elixir client for [Milvus](https://milvus.io/), the open-source vector database built for scalable similarity search.

## Features

- Full gRPC client with automatic reconnection and health monitoring
- Fluent builders for schemas, indexes, and data

## Installation

Add `milvex` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:milvex, "~> 0.4.1"}
  ]
end
```

## Quick Start

### Connect to Milvus

```elixir
# Start a connection
{:ok, conn} = Milvex.Connection.start_link(host: "localhost", port: 19530)

# Or with a named connection
{:ok, _} = Milvex.Connection.start_link([host: "localhost"], name: :milvus)
```

### Start Under a Supervisor

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Milvex.Connection, [host: "localhost", port: 19530, name: MyApp.Milvus]}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

Then use the named connection throughout your app:

```elixir
Milvex.search(MyApp.Milvus, "movies", vectors, vector_field: "embedding")
```

### Define a Schema

```elixir
alias Milvex.Schema
alias Milvex.Schema.Field

schema = Schema.build!(
  name: "movies",
  fields: [
    Field.primary_key("id", :int64, auto_id: true),
    Field.varchar("title", 512),
    Field.vector("embedding", 128)
  ],
  enable_dynamic_field: true
)
```

### Create Collection and Index

```elixir
alias Milvex.Index

# Create collection
:ok = Milvex.create_collection(conn, "movies", schema)

# Create an HNSW index
index = Index.hnsw("embedding", :cosine, m: 16, ef_construction: 256)
:ok = Milvex.create_index(conn, "movies", index)

# Load collection into memory for search
:ok = Milvex.load_collection(conn, "movies")
```

### Insert Data

```elixir
# Insert with auto-fetched schema
{:ok, result} = Milvex.insert(conn, "movies", [
  %{title: "The Matrix", embedding: vector_128d()},
  %{title: "Inception", embedding: vector_128d()}
])

# result.ids contains the auto-generated IDs
```

### Search

```elixir
query_vector = [0.1, 0.2, ...]  # 128-dimensional vector

{:ok, results} = Milvex.search(conn, "movies", [query_vector],
  vector_field: "embedding",
  top_k: 10,
  output_fields: ["title"],
  filter: "title like \"The%\""
)

# Access results
for hit <- results.hits do
  IO.puts("#{hit.id}: #{hit.fields["title"]} (score: #{hit.score})")
end
```

### Query by Expression

```elixir
{:ok, results} = Milvex.query(conn, "movies", "id > 0",
  output_fields: ["id", "title"],
  limit: 100
)
```

## Connection Configuration

```elixir
Milvex.Connection.start_link(
  host: "localhost",        # Milvus server hostname
  port: 19530,              # gRPC port (default: 19530, or 443 for SSL)
  database: "default",      # Database name
  user: "root",             # Username (optional)
  password: "milvus",       # Password (optional)
  token: "api_token",       # API token (alternative to user/password)
  ssl: true,                # Enable SSL/TLS
  ssl_options: [],          # SSL options for transport
  timeout: 30_000           # Connection timeout in ms
)

# Or use a URI
{:ok, config} = Milvex.Config.parse_uri("https://user:pass@milvus.example.com:443/mydb")
{:ok, conn} = Milvex.Connection.start_link(config)
```

## Index Types

```elixir
# HNSW - best for high recall with good performance
Index.hnsw("field", :cosine, m: 16, ef_construction: 256)

# IVF_FLAT - good balance for medium datasets
Index.ivf_flat("field", :l2, nlist: 1024)

# AUTOINDEX - let Milvus choose optimal settings
Index.autoindex("field", :ip)

# IVF_PQ - memory efficient for large datasets
Index.ivf_pq("field", :l2, nlist: 1024, m: 8, nbits: 8)

# DiskANN - for datasets that don't fit in memory
Index.diskann("field", :l2)
```

Metric types: `:l2`, `:ip`, `:cosine`, `:hamming`, `:jaccard`

## Partitions

```elixir
# Create partition
:ok = Milvex.create_partition(conn, "movies", "movies_2024")

# Insert into partition
{:ok, _} = Milvex.insert(conn, "movies", data, partition_name: "movies_2024")

# Search specific partitions
{:ok, _} = Milvex.search(conn, "movies", vectors,
  vector_field: "embedding",
  partition_names: ["movies_2024", "movies_2023"]
)

# Load/release partitions
:ok = Milvex.load_partitions(conn, "movies", ["movies_2024"])
:ok = Milvex.release_partitions(conn, "movies", ["movies_2024"])
```

## Error Handling

All functions return `{:ok, result}` or `{:error, error}`. Bang variants (e.g., `insert!`) raise on error.

```elixir
case Milvex.search(conn, "movies", vectors, vector_field: "embedding") do
  {:ok, results} -> process_results(results)
  {:error, %Milvex.Errors.Connection{}} -> handle_connection_error()
  {:error, %Milvex.Errors.Grpc{code: code}} -> handle_grpc_error(code)
  {:error, %Milvex.Errors.Invalid{field: field}} -> handle_validation_error(field)
end
```

## Development

### Running Tests

```bash
# Unit tests
mix test

# Integration tests (requires Docker)
mix test.integration
```

### Regenerating Proto Files

From the `milvus-proto/proto` directory:

```bash
protoc --elixir_out=one_file_per_module=true,plugins=grpc:../../lib \
       --elixir_opt=package_prefix=milvex \
       --elixir_opt=include_docs=true *.proto
```

## License

MIT
