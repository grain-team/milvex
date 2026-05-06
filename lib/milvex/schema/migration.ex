defmodule Milvex.Schema.Migration do
  @moduledoc """
  Boot-time schema migration for Milvus collections.

  Provides functionality to:
  - Create collections from DSL definitions when missing
  - Verify existing schemas against expected definitions
  - Ensure indexes declared on the DSL are created when missing

  This is the conservative, additive-only path invoked from your application's
  supervision tree. It will never drop or recreate indexes, fields, or the
  collection itself. Operators wanting destructive migrations (drops, index
  recreations) should run `mix milvex.migrate --apply --allow-drop`, which
  exposes the full plan and requires explicit confirmation.

  ## Options

  - `:strict` - When `true`, raises on schema mismatches instead of logging warnings.
    Useful for CI/CD pipelines. Default: `false`

  ## Examples

      # Basic migration
      Milvex.Schema.Migration.migrate!(conn, MyApp.Movies, [])

      # Strict mode (fails on schema mismatch)
      Milvex.Schema.Migration.migrate!(conn, MyApp.Movies, strict: true)
  """
  require Logger

  alias Milvex.Errors.Grpc
  alias Milvex.Errors.Invalid
  alias Milvex.Migration.Operation
  alias Milvex.Migration.Plan

  @type schema_diff :: %{
          missing: [String.t()],
          extra: [String.t()],
          mismatches: [{String.t(), map(), map()}]
        }

  @doc """
  Migrates a collection module to Milvus.

  If the collection exists, verifies the schema matches and ensures any indexes
  declared on the DSL but missing in Milvus are created. If the collection does
  not exist, it is created together with its declared indexes.

  Destructive operations (dropping fields, dropping or recreating indexes) are
  intentionally not performed here. Use `mix milvex.migrate --apply --allow-drop`
  for those.

  ## Options

  - `:strict` - Raise on schema mismatch instead of warning. Default: `false`
  - Any additional options are passed to Milvus API calls.

  ## Returns

  - `:ok` on success
  - Raises `Milvex.Error` on failure
  """
  @spec migrate!(GenServer.server(), module(), keyword()) :: :ok
  def migrate!(connection, collection_module, opts) do
    collection_name = Milvex.Collection.collection_name(collection_module)

    case Milvex.has_collection(connection, collection_name, opts) do
      {:ok, true} ->
        verify_schema!(connection, collection_module, collection_name, opts)
        ensure_indexes!(connection, collection_module, collection_name, opts)

      {:ok, false} ->
        create_collection!(connection, collection_module, collection_name, opts)
        ensure_indexes!(connection, collection_module, collection_name, opts)

      {:error, reason} ->
        raise Grpc.exception(
                operation: :has_collection,
                code: :check_failed,
                message: "Failed to check collection existence: #{format_error(reason)}"
              )
    end

    :ok
  end

  @doc """
  Verifies that the existing collection schema matches the expected schema.

  ## Options

  - `:strict` - Raise on mismatch instead of warning. Default: `false`

  ## Returns

  - `{:ok, :match}` - Schemas match
  - `{:ok, {:mismatch, diff}}` - Schemas differ (only in non-strict mode)
  - Raises in strict mode when schemas don't match
  """
  @spec verify_schema!(GenServer.server(), module(), String.t(), keyword()) ::
          {:ok, :match} | {:ok, {:mismatch, schema_diff()}}
  def verify_schema!(connection, collection_module, collection_name, opts \\ []) do
    expected_schema = Milvex.Collection.to_schema(collection_module)
    strict? = Keyword.get(opts, :strict, false)

    case Milvex.describe_collection(connection, collection_name, opts) do
      {:ok, %{schema: current_schema}} ->
        compare_schemas(expected_schema, current_schema, collection_name, strict?)

      {:error, reason} ->
        raise Grpc.exception(
                operation: :describe_collection,
                code: :fetch_failed,
                message:
                  "Failed to fetch schema for '#{collection_name}': #{format_error(reason)}"
              )
    end
  end

  defp compare_schemas(expected, current, collection_name, strict?) do
    diff =
      expected
      |> Plan.field_diff(current)
      |> project_to_legacy_diff(expected, current)

    if has_differences?(diff) do
      handle_schema_mismatch(collection_name, diff, strict?)
    else
      {:ok, :match}
    end
  end

  defp project_to_legacy_diff(ops, expected, current) do
    expected_fields = Map.new(expected.fields, &{&1.name, &1})
    current_fields = Map.new(current.fields, &{&1.name, &1})

    initial = %{missing: [], extra: [], mismatches: [], seen_alter: MapSet.new()}

    ops
    |> Enum.reduce(initial, &project_op(&1, &2, expected_fields, current_fields))
    |> Map.delete(:seen_alter)
    |> Map.update!(:missing, &Enum.reverse/1)
    |> Map.update!(:extra, &Enum.reverse/1)
    |> Map.update!(:mismatches, &Enum.reverse/1)
  end

  defp project_op(%Operation{kind: :add_field, payload: %{field: field}}, acc, _, _) do
    %{acc | missing: [field.name | acc.missing]}
  end

  defp project_op(%Operation{kind: :drop_field, payload: %{field_name: name}}, acc, _, _) do
    %{acc | extra: [name | acc.extra]}
  end

  defp project_op(
         %Operation{kind: :alter_field, payload: %{field_name: name}},
         acc,
         expected_fields,
         current_fields
       ) do
    record_alter(acc, name, expected_fields, current_fields)
  end

  defp project_op(_op, acc, _, _), do: acc

  defp record_alter(%{seen_alter: seen} = acc, name, expected_fields, current_fields) do
    if MapSet.member?(seen, name) do
      acc
    else
      mismatch = {name, expected_fields[name], current_fields[name]}

      %{
        acc
        | mismatches: [mismatch | acc.mismatches],
          seen_alter: MapSet.put(seen, name)
      }
    end
  end

  defp has_differences?(%{missing: [], extra: [], mismatches: []}), do: false
  defp has_differences?(_), do: true

  defp handle_schema_mismatch(collection_name, diff, true = _strict?) do
    raise Invalid.exception(
            field: :schema,
            message: format_schema_mismatch(collection_name, diff),
            context: diff
          )
  end

  defp handle_schema_mismatch(collection_name, diff, false = _strict?) do
    Logger.warning(format_schema_mismatch(collection_name, diff))
    {:ok, {:mismatch, diff}}
  end

  defp format_schema_mismatch(collection_name, %{
         missing: missing,
         extra: extra,
         mismatches: mismatches
       }) do
    warnings =
      []
      |> add_warning_if(missing != [], "Missing fields in Milvus: #{inspect(missing)}")
      |> add_warning_if(extra != [], "Extra fields in Milvus: #{inspect(extra)}")
      |> Enum.concat(Enum.map(mismatches, &format_mismatch/1))
      |> Enum.reverse()

    """
    Schema mismatch detected for collection '#{collection_name}'.
    Manual intervention may be required.
    #{Enum.join(warnings, "\n")}
    """
  end

  defp add_warning_if(warnings, false, _msg), do: warnings
  defp add_warning_if(warnings, true, msg), do: [msg | warnings]

  defp format_mismatch({name, expected, current}) do
    "Field '#{name}' mismatch: expected #{format_field(expected)}, got #{format_field(current)}"
  end

  defp format_field(field) do
    base = to_string(field.data_type)

    attrs =
      []
      |> add_attr_if(field.dimension, "dim=#{field.dimension}")
      |> add_attr_if(field.max_length, "max_length=#{field.max_length}")
      |> add_attr_if(field.nullable, "nullable")
      |> add_attr_if(field.is_partition_key, "partition_key")
      |> add_attr_if(field.is_clustering_key, "clustering_key")
      |> add_attr_if(field.element_type, "element=#{field.element_type}")
      |> add_attr_if(field.max_capacity, "max_capacity=#{field.max_capacity}")

    case attrs do
      [] -> base
      _ -> "#{base}(#{Enum.join(attrs, ", ")})"
    end
  end

  defp add_attr_if(attrs, nil, _), do: attrs
  defp add_attr_if(attrs, false, _), do: attrs
  defp add_attr_if(attrs, _, attr), do: [attr | attrs]

  defp ensure_indexes!(connection, collection_module, collection_name, opts) do
    if function_exported?(collection_module, :index_config, 0) do
      indexes = collection_module.index_config()
      Enum.each(indexes, &ensure_index_create_only!(connection, collection_name, &1, opts))
    end
  end

  defp ensure_index_create_only!(
         connection,
         collection_name,
         %Milvex.Index{} = desired_index,
         opts
       ) do
    field_name = desired_index.field_name

    case get_current_index(connection, collection_name, field_name, opts) do
      {:ok, nil} ->
        create_index!(connection, collection_name, desired_index, opts)

      {:ok, _existing} ->
        Logger.debug(
          "Index on '#{field_name}' present; boot-time migration leaves it unchanged. " <>
            "Run `mix milvex.migrate --apply --allow-drop` to recreate."
        )

      {:error, reason} ->
        raise Grpc.exception(
                operation: :describe_index,
                code: :fetch_failed,
                message: "Failed to check index on '#{field_name}': #{format_error(reason)}"
              )
    end
  end

  defp get_current_index(connection, collection_name, field_name, opts) do
    case Milvex.describe_index(
           connection,
           collection_name,
           Keyword.put(opts, :field_name, field_name)
         ) do
      {:ok, index_descriptions} ->
        matching = Enum.find(index_descriptions, fn desc -> desc.field_name == field_name end)
        {:ok, matching}

      {:error, %{code: 700}} ->
        {:ok, nil}

      {:error, %{message: msg}} when is_binary(msg) ->
        if String.contains?(msg, "index not found") do
          {:ok, nil}
        else
          {:error, msg}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp create_index!(connection, collection_name, %Milvex.Index{} = index, opts) do
    case Milvex.create_index(connection, collection_name, index, opts) do
      :ok ->
        Logger.info("Created index on '#{index.field_name}' for #{collection_name}")

      {:error, reason} ->
        raise Grpc.exception(
                operation: :create_index,
                code: :create_failed,
                message:
                  "Failed to create index on '#{index.field_name}': #{format_error(reason)}"
              )
    end
  end

  defp create_collection!(connection, collection_module, collection_name, opts) do
    schema = Milvex.Collection.to_schema(collection_module)

    case Milvex.create_collection(connection, collection_name, schema, opts) do
      :ok ->
        Logger.info("Created Milvus collection: #{collection_name}")

      {:error, reason} ->
        raise Grpc.exception(
                operation: :create_collection,
                code: :create_failed,
                message:
                  "Failed to create collection '#{collection_name}': #{format_error(reason)}"
              )
    end
  end

  defp format_error(error) when is_exception(error), do: Exception.message(error)
  defp format_error(error), do: to_string(error)
end
