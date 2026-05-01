defmodule Milvex.Internal do
  @moduledoc false

  require Logger

  alias Milvex.Errors.Invalid
  alias Milvex.Highlighter, as: MilvexHighlighter
  alias Milvex.Schema
  alias Milvex.Schema.Field

  alias Milvex.Milvus.Proto.Common.Highlighter, as: ProtoHighlighter
  alias Milvex.Milvus.Proto.Common.KeyValuePair
  alias Milvex.Milvus.Proto.Common.PlaceholderGroup
  alias Milvex.Milvus.Proto.Common.PlaceholderValue

  @nested_field_regex ~r/^(\w+)\[(\w+)\]$/

  @doc false
  @spec resolve_collection_name(Milvex.collection_ref()) :: String.t()
  def resolve_collection_name(name) when is_binary(name), do: name

  def resolve_collection_name(module) when is_atom(module) do
    Milvex.Collection.collection_name(module)
  end

  @doc false
  @spec resolve_schema(
          GenServer.server(),
          Milvex.collection_ref(),
          String.t(),
          keyword(),
          (GenServer.server(), Milvex.collection_ref(), keyword() ->
             {:ok, map()} | {:error, Milvex.Error.t()})
        ) :: {:ok, Schema.t()} | {:error, Milvex.Error.t()}
  def resolve_schema(_conn, module, _collection_name, _opts, _describe_fun)
      when is_atom(module) do
    {:ok, Milvex.Collection.to_schema(module)}
  end

  def resolve_schema(conn, name, collection_name, opts, describe_fun) when is_binary(name) do
    Logger.warning(
      "Passing a collection name string to search/hybrid_search triggers a " <>
        "describe_collection RPC on every call. Pass a Collection module instead. " <>
        "String-based schema resolution will be deprecated in a future version."
    )

    with {:ok, info} <- describe_fun.(conn, collection_name, opts) do
      {:ok, info.schema}
    end
  end

  @doc false
  @spec find_vector_field(Schema.t(), String.t()) ::
          {:ok, Field.t(), boolean()} | {:error, Milvex.Error.t()}
  def find_vector_field(schema, field_name) do
    case parse_nested_field_name(field_name) do
      {:nested, parent_name, child_name} ->
        find_nested_vector_field(schema, field_name, parent_name, child_name)

      :simple ->
        find_simple_vector_field(schema, field_name)
    end
  end

  defp parse_nested_field_name(field_name) do
    case Regex.run(@nested_field_regex, field_name) do
      [_, parent, child] -> {:nested, parent, child}
      nil -> :simple
    end
  end

  defp find_simple_vector_field(schema, field_name) do
    case Schema.get_field(schema, field_name) do
      nil ->
        {:error,
         Invalid.exception(field: :vector_field, message: "Field '#{field_name}' not found")}

      field ->
        if Field.vector_type?(field.data_type) do
          {:ok, field, false}
        else
          {:error,
           Invalid.exception(
             field: :vector_field,
             message: "Field '#{field_name}' is not a vector field"
           )}
        end
    end
  end

  defp find_nested_vector_field(schema, full_name, parent_name, child_name) do
    case Schema.get_field(schema, parent_name) do
      nil ->
        {:error,
         Invalid.exception(field: :vector_field, message: "Field '#{full_name}' not found")}

      %{data_type: :array_of_struct, struct_schema: struct_schema} when is_list(struct_schema) ->
        find_child_vector_field(struct_schema, full_name, child_name)

      _ ->
        {:error,
         Invalid.exception(
           field: :vector_field,
           message: "Field '#{parent_name}' is not an array_of_struct field"
         )}
    end
  end

  defp find_child_vector_field(struct_schema, full_name, child_name) do
    case Enum.find(struct_schema, &(&1.name == child_name)) do
      nil ->
        {:error,
         Invalid.exception(field: :vector_field, message: "Field '#{full_name}' not found")}

      field ->
        validate_nested_vector_field(field, full_name)
    end
  end

  defp validate_nested_vector_field(field, full_name) do
    if Field.vector_type?(field.data_type) do
      {:ok, field, true}
    else
      {:error,
       Invalid.exception(
         field: :vector_field,
         message: "Field '#{full_name}' is not a vector field"
       )}
    end
  end

  @doc false
  @spec build_ann_placeholder_group([list() | binary()], Field.t(), boolean()) ::
          {:ok, binary()} | {:error, Milvex.Error.t()}
  def build_ann_placeholder_group(data, field, is_nested) do
    cond do
      all_vectors_data?(data) -> build_placeholder_group(data, field, is_nested)
      all_strings_data?(data) -> build_text_placeholder_group(data)
      true -> {:error, Invalid.exception(field: :data, message: "invalid data format")}
    end
  end

  defp all_vectors_data?(data), do: Enum.all?(data, &is_list/1)
  defp all_strings_data?(data), do: Enum.all?(data, &is_binary/1)

  @doc false
  @spec build_text_placeholder_group([String.t()]) ::
          {:ok, binary()} | {:error, Milvex.Error.t()}
  def build_text_placeholder_group(texts) do
    placeholder = %PlaceholderValue{
      tag: "$0",
      type: :VarChar,
      values: texts
    }

    group = %PlaceholderGroup{placeholders: [placeholder]}
    {:ok, PlaceholderGroup.encode(group)}
  rescue
    e ->
      {:error, Invalid.exception(field: :data, message: "Failed to encode text: #{inspect(e)}")}
  end

  defp build_placeholder_group(vectors, field, is_nested) do
    placeholder_type = vector_type_to_placeholder_type(field.data_type, is_nested)
    dim = field.dimension

    encoded_values =
      Enum.map(vectors, fn vec ->
        encode_vector(vec, field.data_type, dim)
      end)

    placeholder = %PlaceholderValue{
      tag: "$0",
      type: placeholder_type,
      values: encoded_values
    }

    group = %PlaceholderGroup{placeholders: [placeholder]}
    {:ok, PlaceholderGroup.encode(group)}
  rescue
    e ->
      {:error,
       Invalid.exception(field: :vectors, message: "Failed to encode vectors: #{inspect(e)}")}
  end

  defp vector_type_to_placeholder_type(type, true) do
    case type do
      :float_vector -> :EmbListFloatVector
      :binary_vector -> :EmbListBinaryVector
      :float16_vector -> :EmbListFloat16Vector
      :bfloat16_vector -> :EmbListBFloat16Vector
      :sparse_float_vector -> :EmbListSparseFloatVector
      :int8_vector -> :EmbListInt8Vector
      _ -> :EmbListFloatVector
    end
  end

  defp vector_type_to_placeholder_type(type, false) do
    case type do
      :float_vector -> :FloatVector
      :binary_vector -> :BinaryVector
      :float16_vector -> :Float16Vector
      :bfloat16_vector -> :BFloat16Vector
      :sparse_float_vector -> :SparseFloatVector
      :int8_vector -> :Int8Vector
      _ -> :FloatVector
    end
  end

  defp encode_vector(vec, :float_vector, _dim) do
    vec
    |> Enum.map(&float_to_binary/1)
    |> IO.iodata_to_binary()
  end

  defp encode_vector(vec, :binary_vector, _dim) do
    IO.iodata_to_binary(vec)
  end

  defp encode_vector(vec, _type, _dim) do
    vec
    |> Enum.map(&float_to_binary/1)
    |> IO.iodata_to_binary()
  end

  defp float_to_binary(f) when is_float(f), do: <<f::little-float-32>>
  defp float_to_binary(i) when is_integer(i), do: <<i * 1.0::little-float-32>>

  @doc false
  @spec build_highlighter(MilvexHighlighter.t() | nil) :: ProtoHighlighter.t() | nil
  def build_highlighter(nil), do: nil

  def build_highlighter(%MilvexHighlighter{type: type, params: params}) do
    proto_type =
      case type do
        :lexical -> :Lexical
        :semantic -> :Semantic
      end

    kvs =
      Enum.map(params, fn {key, value} ->
        %KeyValuePair{key: to_string(key), value: encode_highlighter_value(value)}
      end)

    %ProtoHighlighter{type: proto_type, params: kvs}
  end

  defp encode_highlighter_value(value) when is_list(value), do: Jason.encode!(value)
  defp encode_highlighter_value(value) when is_binary(value), do: value
  defp encode_highlighter_value(value) when is_boolean(value), do: to_string(value)
  defp encode_highlighter_value(value) when is_number(value), do: to_string(value)
end
