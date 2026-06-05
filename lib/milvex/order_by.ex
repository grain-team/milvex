defmodule Milvex.OrderBy do
  @moduledoc """
  Translates the `:order_by` option for `Milvex.query/4` into the Milvus
  `order_by_fields` query parameter.

  Milvus encodes result ordering as a single `KeyValuePair` whose value is a
  comma-joined list of `"field:direction"` segments, e.g.
  `"price:desc,rating:asc"`.

  ## Accepted forms

    - `:price` / `"price"` -> `"price:asc"`
    - `[:price, :rating]` -> `"price:asc,rating:asc"`
    - `[desc: :price]` -> `"price:desc"`
    - `[desc: :price, asc: :rating]` -> `"price:desc,rating:asc"`
    - `[:price, desc: :rating]` -> `"price:asc,rating:desc"`
    - `nil` / `[]` -> no parameter

  Directions are `:asc` or `:desc`. Field names may be atoms or strings.
  """

  alias Milvex.Errors.Invalid
  alias Milvex.Milvus.Proto.Common.KeyValuePair

  @key "order_by_fields"

  @doc """
  Converts an `:order_by` option value into an `order_by_fields` `KeyValuePair`.

  Returns `{:ok, nil}` when there is nothing to order by, `{:ok, kv}` with the
  built `KeyValuePair`, or `{:error, %Milvex.Errors.Invalid{}}` on bad input.
  """
  @spec to_param(term()) :: {:ok, KeyValuePair.t() | nil} | {:error, Invalid.t()}
  def to_param(nil), do: {:ok, nil}
  def to_param([]), do: {:ok, nil}

  def to_param(order_by) do
    with {:ok, segments} <- reduce_segments(List.wrap(order_by)) do
      {:ok, %KeyValuePair{key: @key, value: Enum.join(segments, ",")}}
    end
  end

  defp reduce_segments(elements) do
    result =
      Enum.reduce_while(elements, {:ok, []}, fn element, {:ok, acc} ->
        case segment(element) do
          {:ok, seg} -> {:cont, {:ok, [seg | acc]}}
          {:error, _} = error -> {:halt, error}
        end
      end)

    case result do
      {:ok, segs} -> {:ok, Enum.reverse(segs)}
      {:error, _} = error -> error
    end
  end

  defp segment({direction, field}) when direction in [:asc, :desc] do
    with {:ok, name} <- field_name(field) do
      {:ok, "#{name}:#{direction}"}
    end
  end

  defp segment({direction, _field}) do
    {:error,
     Invalid.exception(
       field: :order_by,
       message: "invalid order direction #{inspect(direction)}; expected :asc or :desc"
     )}
  end

  defp segment(field) when (is_atom(field) and not is_boolean(field)) or is_binary(field) do
    with {:ok, name} <- field_name(field) do
      {:ok, "#{name}:asc"}
    end
  end

  defp segment(other) do
    {:error,
     Invalid.exception(
       field: :order_by,
       message:
         "invalid order_by entry #{inspect(other)}; expected a field name or {:asc | :desc, field}"
     )}
  end

  defp field_name(field) when is_atom(field) and not is_nil(field) do
    field |> Atom.to_string() |> validate_name()
  end

  defp field_name(field) when is_binary(field), do: validate_name(field)

  defp field_name(other) do
    {:error, Invalid.exception(field: :order_by, message: "invalid field name #{inspect(other)}")}
  end

  defp validate_name(name) do
    case String.trim(name) do
      "" -> {:error, Invalid.exception(field: :order_by, message: "field name must not be blank")}
      trimmed -> {:ok, trimmed}
    end
  end
end
