defmodule Milvex.ExprParams do
  @moduledoc """
  Converts Elixir values to Milvus `TemplateValue` protobuf structs for filter expression templating.

  Filter templates allow parameterized filter expressions using `{placeholder}` syntax,
  where values are substituted at query time by Milvus. This improves performance by
  reducing expression parsing overhead, especially with large arrays or complex expressions.

  ## Supported types

    - `boolean` -> `bool_val`
    - `integer` -> `int64_val`
    - `float` -> `float_val`
    - `string` -> `string_val`
    - `[boolean]` -> `BoolArray`
    - `[integer]` -> `LongArray`
    - `[float]` -> `DoubleArray`
    - `[string]` -> `StringArray`
  """

  alias Milvex.Milvus.Proto.Schema.BoolArray
  alias Milvex.Milvus.Proto.Schema.DoubleArray
  alias Milvex.Milvus.Proto.Schema.LongArray
  alias Milvex.Milvus.Proto.Schema.StringArray
  alias Milvex.Milvus.Proto.Schema.TemplateArrayValue
  alias Milvex.Milvus.Proto.Schema.TemplateValue

  @doc """
  Converts a map of parameter names to Elixir values into a map of `TemplateValue` protobuf structs.

  Returns an empty map when given `nil` or an empty map.
  """
  @spec to_proto(map() | nil) :: %{String.t() => TemplateValue.t()}
  def to_proto(nil), do: %{}
  def to_proto(params) when map_size(params) == 0, do: %{}

  def to_proto(params) when is_map(params) do
    Map.new(params, fn {key, value} ->
      {to_string(key), convert_value(value)}
    end)
  end

  defp convert_value(value) when is_boolean(value) do
    %TemplateValue{val: {:bool_val, value}}
  end

  defp convert_value(value) when is_integer(value) do
    %TemplateValue{val: {:int64_val, value}}
  end

  defp convert_value(value) when is_float(value) do
    %TemplateValue{val: {:float_val, value}}
  end

  defp convert_value(value) when is_binary(value) do
    %TemplateValue{val: {:string_val, value}}
  end

  defp convert_value([first | _] = list) when is_boolean(first) do
    %TemplateValue{
      val: {:array_val, %TemplateArrayValue{data: {:bool_data, %BoolArray{data: list}}}}
    }
  end

  defp convert_value([first | _] = list) when is_integer(first) do
    %TemplateValue{
      val: {:array_val, %TemplateArrayValue{data: {:long_data, %LongArray{data: list}}}}
    }
  end

  defp convert_value([first | _] = list) when is_float(first) do
    %TemplateValue{
      val: {:array_val, %TemplateArrayValue{data: {:double_data, %DoubleArray{data: list}}}}
    }
  end

  defp convert_value([first | _] = list) when is_binary(first) do
    %TemplateValue{
      val: {:array_val, %TemplateArrayValue{data: {:string_data, %StringArray{data: list}}}}
    }
  end
end
