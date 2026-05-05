defmodule Milvex.Migration.Version do
  @moduledoc """
  Helpers for normalising and comparing Milvus version strings.

  Milvus reports versions like `"v2.6.1"`, `"2.6.1"`, or `"2.6.1-dev"`. This
  module provides a single coercion entry point used by both `Plan` and
  `Operation` so behaviour stays consistent.

  The cutoff at which Milvus gained native field/function drop support is
  exposed via `drop_field_supported_at/0` (currently `"2.6.0"`).
  """

  @drop_field_supported_at "2.6.0"

  @doc """
  Normalises a Milvus version string into a strict semver string suitable
  for `Version.compare/2`.

  Trims whitespace, strips a leading `v`, and drops any pre-release suffix.

      iex> Milvex.Migration.Version.coerce("v2.6.1")
      "2.6.1"

      iex> Milvex.Migration.Version.coerce("2.6.1")
      "2.6.1"

      iex> Milvex.Migration.Version.coerce("2.6.1-dev")
      "2.6.1"

      iex> Milvex.Migration.Version.coerce("  v2.6.1  ")
      "2.6.1"
  """
  @spec coerce(String.t()) :: String.t()
  def coerce(version) when is_binary(version) do
    version
    |> String.trim()
    |> String.trim_leading("v")
    |> String.split("-", parts: 2)
    |> hd()
  end

  @doc """
  Returns the Milvus version at which native field/function drop is
  supported. Versions below this require collection recreation.
  """
  @spec drop_field_supported_at() :: String.t()
  def drop_field_supported_at, do: @drop_field_supported_at
end
