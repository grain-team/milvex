defmodule Milvex.Migration.Operation do
  @moduledoc """
  Single unit of work exchanged between `Milvex.Migration.Plan`,
  `Milvex.Migration.Runner`, and `Milvex.Migration.Reporter`.

  An `Operation` describes one logical schema mutation (add/alter/drop a field,
  create/alter/recreate/drop an index, add/alter/drop a function, alter
  collection KV, create collection) plus the metadata needed to display, plan
  releases for, and serialise it.

  Categories:

    * `:additive`     — safe forward-compatible change (adds capability)
    * `:destructive`  — removes data or capability; may need release on older
                        Milvus versions
    * `:impossible`   — diff cannot be reconciled in-place; report only
    * `:descriptive`  — comment / description update; no schema effect

  `requires_release` is derived from `(kind, milvus_version)` by
  `requires_release?/2`. Modern Milvus (>= 2.6.0) is permissive: drops do not
  require release. Older versions need release for field/function drops. Index
  drops and recreations always require release.
  """

  alias Milvex.Function
  alias Milvex.Index
  alias Milvex.Migration.Version, as: MigrationVersion
  alias Milvex.Schema
  alias Milvex.Schema.Field

  @type kind ::
          :create_collection
          | :alter_collection
          | :add_field
          | :alter_field
          | :drop_field
          | :description_change
          | :create_index
          | :alter_index
          | :drop_index
          | :recreate_index
          | :add_function
          | :alter_function
          | :drop_function

  @type category :: :additive | :destructive | :impossible | :descriptive

  @type t :: %__MODULE__{
          kind: kind(),
          category: category(),
          collection_name: String.t(),
          payload: map(),
          reason: String.t() | nil,
          requires_release: boolean()
        }

  @enforce_keys [:kind, :category, :collection_name, :payload]
  defstruct [:kind, :category, :collection_name, :payload, :reason, requires_release: false]

  @doc """
  Builds an operation, deriving `requires_release` from `(kind, version)`.

  Pass `reason: "..."` in `opts` to attach a human explanation, used for
  `:impossible` ops in the reporter.
  """
  @spec build(kind(), category(), String.t(), map(), String.t(), keyword()) :: t()
  def build(kind, category, collection_name, payload, milvus_version, opts \\ []) do
    %__MODULE__{
      kind: kind,
      category: category,
      collection_name: collection_name,
      payload: payload,
      reason: Keyword.get(opts, :reason),
      requires_release: requires_release?(kind, milvus_version)
    }
  end

  @doc """
  Returns whether the given operation kind requires the collection to be
  released before it can be applied on the given Milvus version.

    * `:drop_index`, `:recreate_index` — always true
    * `:drop_field`, `:drop_function`  — true only on Milvus < 2.6.0
    * everything else                  — false
  """
  @spec requires_release?(kind(), String.t()) :: boolean()
  def requires_release?(:drop_index, _version), do: true
  def requires_release?(:recreate_index, _version), do: true

  def requires_release?(kind, version) when kind in [:drop_field, :drop_function] do
    Version.compare(MigrationVersion.coerce(version), MigrationVersion.drop_field_supported_at()) ==
      :lt
  end

  def requires_release?(_kind, _version), do: false

  @doc """
  Renders the operation as one line of iodata for the text reporter.

  The first character is a sigil derived from the category:

    * `:additive`    → `+`
    * `:destructive` → `-`
    * `:descriptive` → `~`
    * `:impossible`  → `!`
  """
  @spec to_line(t()) :: iodata()
  def to_line(%__MODULE__{} = op) do
    [sigil(op.category), " ", render_kind(op.kind), " ", render_target(op)]
  end

  defp sigil(:additive), do: "+"
  defp sigil(:destructive), do: "-"
  defp sigil(:descriptive), do: "~"
  defp sigil(:impossible), do: "!"

  defp render_kind(:create_collection), do: "create collection"
  defp render_kind(:alter_collection), do: "alter collection"
  defp render_kind(:add_field), do: "add field"
  defp render_kind(:alter_field), do: "alter field"
  defp render_kind(:drop_field), do: "drop field"
  defp render_kind(:description_change), do: "description"
  defp render_kind(:create_index), do: "create index"
  defp render_kind(:alter_index), do: "alter index"
  defp render_kind(:drop_index), do: "drop index"
  defp render_kind(:recreate_index), do: "recreate index"
  defp render_kind(:add_function), do: "add function"
  defp render_kind(:alter_function), do: "alter function"
  defp render_kind(:drop_function), do: "drop function"

  defp render_target(%__MODULE__{kind: :add_field, payload: %{field: %Field{} = f}}) do
    [f.name, " ", to_string(f.data_type), field_modifiers(f)]
  end

  defp render_target(%__MODULE__{kind: :alter_field, payload: %{field_name: name, changes: ch}}) do
    [name, " ", inspect(ch)]
  end

  defp render_target(%__MODULE__{kind: :drop_field, payload: %{field_name: name}}) do
    [name]
  end

  defp render_target(%__MODULE__{
         kind: :description_change,
         payload: %{field_name: name, from: from, to: to}
       }) do
    [name, " ", inspect(from), " -> ", inspect(to)]
  end

  defp render_target(%__MODULE__{kind: :create_index, payload: %{index: %Index{} = idx}}) do
    [idx.field_name, " ", to_string(idx.index_type)]
  end

  defp render_target(%__MODULE__{
         kind: :alter_index,
         payload: %{index_name: name, changes: ch}
       }) do
    [name, " ", inspect(ch)]
  end

  defp render_target(%__MODULE__{
         kind: :drop_index,
         payload: %{index_name: name}
       }) do
    [name]
  end

  defp render_target(%__MODULE__{
         kind: :recreate_index,
         payload: %{field_name: name}
       }) do
    [name]
  end

  defp render_target(%__MODULE__{kind: :add_function, payload: %{function: %Function{} = f}}) do
    [f.name, " ", to_string(f.type)]
  end

  defp render_target(%__MODULE__{
         kind: :alter_function,
         payload: %{function_name: name, changes: ch}
       }) do
    [name, " ", inspect(ch)]
  end

  defp render_target(%__MODULE__{kind: :drop_function, payload: %{function_name: name}}) do
    [name]
  end

  defp render_target(%__MODULE__{kind: :create_collection, payload: %{schema: %Schema{} = s}}) do
    [s.name]
  end

  defp render_target(%__MODULE__{kind: :alter_collection, collection_name: name, payload: p}) do
    [name, " ", inspect(p)]
  end

  defp render_target(%__MODULE__{collection_name: name, payload: p}) do
    [name, " ", inspect(p)]
  end

  defp field_modifiers(%Field{} = f) do
    parts =
      []
      |> maybe_modifier("(#{f.max_length})", f.max_length && f.data_type == :varchar)
      |> maybe_modifier("dim=#{f.dimension}", f.dimension)
      |> maybe_modifier("nullable", f.nullable)
      |> maybe_modifier("pk", f.is_primary_key)

    case parts do
      [] -> []
      list -> [" ", Enum.intersperse(list, " ")]
    end
  end

  defp maybe_modifier(parts, _str, false), do: parts
  defp maybe_modifier(parts, _str, nil), do: parts
  defp maybe_modifier(parts, str, _), do: parts ++ [str]

  @doc """
  Converts the operation to a JSON-serialisable map.

  Each kind has a clause normalising its payload to a canonical shape:
  field/index/function structs are projected to small maps containing only
  identifying keys.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = op) do
    base = %{kind: op.kind, category: op.category}
    Map.merge(base, payload_to_map(op.kind, op.payload))
  end

  defp payload_to_map(:add_field, %{field: %Field{} = field}) do
    %{field: field_to_map(field)}
  end

  defp payload_to_map(:alter_field, %{field_name: name, changes: changes}) do
    %{field_name: name, changes: changes}
  end

  defp payload_to_map(:drop_field, %{field_name: name}) do
    %{field_name: name}
  end

  defp payload_to_map(:description_change, %{field_name: name, from: from, to: to}) do
    %{field_name: name, from: from, to: to}
  end

  defp payload_to_map(:create_index, %{index: %Index{} = idx}) do
    %{index: index_to_map(idx)}
  end

  defp payload_to_map(:alter_index, %{index_name: name, changes: changes}) do
    %{index_name: name, changes: changes}
  end

  defp payload_to_map(:drop_index, payload) do
    Map.take(payload, [:field_name, :index_name])
  end

  defp payload_to_map(:recreate_index, %{field_name: name, old: old, new: new}) do
    %{field_name: name, old: index_summary(old), new: index_summary(new)}
  end

  defp payload_to_map(:add_function, %{function: %Function{} = fun}) do
    %{function: function_to_map(fun)}
  end

  defp payload_to_map(:alter_function, %{function_name: name, changes: changes}) do
    %{function_name: name, changes: changes}
  end

  defp payload_to_map(:drop_function, %{function_name: name}) do
    %{function_name: name}
  end

  defp payload_to_map(:create_collection, %{schema: %Schema{} = schema}) do
    %{schema: schema_to_map(schema)}
  end

  defp payload_to_map(:alter_collection, payload) when is_map(payload) do
    payload
  end

  defp payload_to_map(_kind, payload) do
    %{payload: payload}
  end

  defp field_to_map(%Field{} = field) do
    %{
      name: field.name,
      data_type: field.data_type,
      dimension: field.dimension,
      max_length: field.max_length,
      nullable: field.nullable,
      default_value: field.default_value,
      is_primary_key: field.is_primary_key,
      auto_id: field.auto_id,
      is_partition_key: field.is_partition_key,
      is_clustering_key: field.is_clustering_key,
      description: field.description
    }
    |> drop_nil_values()
  end

  defp index_to_map(%Index{} = idx) do
    %{
      name: idx.name,
      field_name: idx.field_name,
      index_type: idx.index_type,
      metric_type: idx.metric_type,
      params: idx.params
    }
    |> drop_nil_values()
  end

  defp index_summary(%Index{} = idx), do: index_to_map(idx)
  defp index_summary(other) when is_map(other), do: other

  defp function_to_map(%Function{} = fun) do
    %{
      name: fun.name,
      type: fun.type,
      input_field_names: fun.input_field_names,
      output_field_names: fun.output_field_names,
      params: fun.params
    }
  end

  defp schema_to_map(%Schema{} = schema) do
    %{
      name: schema.name,
      description: schema.description,
      fields: Enum.map(schema.fields, &field_to_map/1)
    }
    |> drop_nil_values()
  end

  defp drop_nil_values(map) do
    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end
end
