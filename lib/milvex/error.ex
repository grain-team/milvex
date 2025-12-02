defmodule Milvex.Error do
  @moduledoc """
  Main error aggregator for Milvex using Splode.

  This module provides consistent error handling across all Milvex operations.
  Errors are classified into four categories:

  - `:invalid` - Input validation and constraint violations
  - `:connection` - Network and connection establishment errors
  - `:grpc` - gRPC operation and Milvus server response errors
  - `:unknown` - Unexpected or unclassified errors
  """

  use Splode,
    error_classes: [
      invalid: Milvex.Errors.Invalid,
      connection: Milvex.Errors.Connection,
      grpc: Milvex.Errors.Grpc,
      unknown: Milvex.Errors.Unknown
    ],
    unknown_error: Milvex.Errors.Unknown
end
