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
  @fallback_version "0.0.0"

  @doc """
  Normalises a Milvus version string into a strict `MAJOR.MINOR.PATCH` semver
  string suitable for `Version.compare/2`.

  Trims whitespace, strips a leading `v`, drops any pre-release (`-`) or build
  (`+`) suffix, pads missing components to three, and truncates extras. A string
  with no leading numeric component falls back to `#{@fallback_version}` so a
  malformed server version is treated conservatively (pre-2.6) rather than
  raising.

      iex> Milvex.Migration.Version.coerce("v2.6.1")
      "2.6.1"

      iex> Milvex.Migration.Version.coerce("2.6.1")
      "2.6.1"

      iex> Milvex.Migration.Version.coerce("2.6.1-dev")
      "2.6.1"

      iex> Milvex.Migration.Version.coerce("  v2.6.1  ")
      "2.6.1"

      iex> Milvex.Migration.Version.coerce("2.6")
      "2.6.0"

      iex> Milvex.Migration.Version.coerce("2.6.1+build.5")
      "2.6.1"

      iex> Milvex.Migration.Version.coerce("")
      "0.0.0"
  """
  @spec coerce(String.t()) :: String.t()
  def coerce(version) when is_binary(version) do
    version
    |> String.trim()
    |> String.trim_leading("v")
    |> String.split(["-", "+"], parts: 2)
    |> hd()
    |> to_semver()
  end

  defp to_semver(core) do
    components =
      core
      |> String.split(".")
      |> Enum.map(&parse_component/1)
      |> Enum.take_while(&is_integer/1)

    case components do
      [] -> @fallback_version
      nums -> nums |> Enum.take(3) |> pad_to_three() |> Enum.join(".")
    end
  end

  defp parse_component(part) do
    case Integer.parse(part) do
      {n, _rest} when n >= 0 -> n
      _ -> nil
    end
  end

  defp pad_to_three(nums), do: nums ++ List.duplicate(0, 3 - length(nums))

  @doc """
  Returns the Milvus version at which native field/function drop is
  supported. Versions below this require collection recreation.
  """
  @spec drop_field_supported_at() :: String.t()
  def drop_field_supported_at, do: @drop_field_supported_at
end
