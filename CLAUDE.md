# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Milvex is an Elixir client for the Milvus vector database. It provides a high-level API for vector operations (insert, search, query) and collection management over gRPC.

## Common Commands

```bash
# Run unit tests (excludes integration tests)
mix test

# Run integration tests (requires Docker for testcontainers)
mix test.integration

# Run a specific test file
mix test test/milvex/schema_test.exs

# Run a specific test by line number
mix test test/milvex/schema_test.exs:42

# Format code
mix format

# Run linter
mix credo

# Run type checker
mix dialyzer

# Run benchmarks
mix bench.all
mix bench.field_data
mix bench.data
mix bench.result
```

## Architecture

### Core Modules

- `Milvex` (`lib/milvex.ex`) - High-level client API. All collection, partition, index, and data operations go through here. Each operation has a raising variant (e.g., `insert!`).

- `Milvex.Connection` (`lib/milvex/connection.ex`) - GenStateMachine managing gRPC channel lifecycle. States: `:connecting` -> `:connected` <-> `:reconnecting`. Handles automatic reconnection and health checks.

- `Milvex.RPC` (`lib/milvex/rpc.ex`) - Low-level gRPC wrapper. Converts Milvus proto Status codes and gRPC errors to Splode errors.

### Data Layer

- `Milvex.Schema` / `Milvex.Schema.Field` - Fluent builders for collection schemas. Supports validation and proto conversion.

- `Milvex.Data` / `Milvex.Data.FieldData` - Converts row-oriented Elixir data to column-oriented FieldData format for Milvus inserts.

- `Milvex.Index` - Builder for index configurations (HNSW, IVF_FLAT, AUTOINDEX, etc.) with validation.

- `Milvex.SearchResult` / `Milvex.QueryResult` - Parse and structure Milvus response data.

### Error Handling

Uses Splode for structured errors. Error types in `Milvex.Error`:
- `:invalid` - Input validation errors
- `:connection` - Network/connection errors
- `:grpc` - gRPC/Milvus server errors
- `:unknown` - Unclassified errors

### Generated Proto Files

`lib/milvex/milvus/proto/` contains generated Elixir modules from Milvus protobuf definitions. Regenerate with:
```bash
cd milvus-proto/proto
protoc --elixir_out=one_file_per_module=true,plugins=grpc:../../lib \
       --elixir_opt=package_prefix=milvex \
       --elixir_opt=include_docs=true *.proto
```

## Testing

- Unit tests use Mimic for mocking `Milvex.Connection` and `Milvex.RPC`
- Integration tests use testcontainers to spin up a real Milvus instance
- Integration tests are tagged with `@tag :integration` and excluded by default
- `Milvex.IntegrationCase` provides common setup and helpers for integration tests

## Key Conventions

- All public API functions have raising variants (suffix `!`)
- Field names can be atoms or strings (normalized internally to strings)
- Schemas and data builders follow a fluent/pipeline pattern
- Validation uses Zoi for schema validation
