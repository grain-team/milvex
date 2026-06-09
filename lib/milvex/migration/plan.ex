defmodule Milvex.Migration.Plan do
  @moduledoc """
  Pure diff between a `Milvex.Collection` DSL module and the live Milvus state.

  `diff/4` produces a `%Plan{}` carrying a list of `%Milvex.Migration.Operation{}`
  describing every change required to bring the live collection in line with the
  DSL. The function is pure: no RPCs, no side effects.

  Live state shape:

      %{
        schema: %Milvex.Schema{},
        indexes: [%Milvex.Milvus.Proto.Milvus.IndexDescription{}],
        collection_props: keyword()
      }

  Pass `nil` when the collection does not exist; the plan will then contain a
  `:create_collection` followed by one `:create_index` per entry in
  `module.index_config/0` (if exported).
  """

  alias Milvex.Function
  alias Milvex.Index
  alias Milvex.Migration.Operation
  alias Milvex.Migration.Version, as: MigrationVersion
  alias Milvex.Milvus.Proto.Common.KeyValuePair
  alias Milvex.Milvus.Proto.Milvus.IndexDescription
  alias Milvex.Schema
  alias Milvex.Schema.Field

  @structural_int_param_keys [:M, :efConstruction, :nlist, :m, :nbits]
  @structural_int_param_strings Enum.map(@structural_int_param_keys, &Atom.to_string/1)

  @vector_types [
    :float_vector,
    :binary_vector,
    :float16_vector,
    :bfloat16_vector,
    :sparse_float_vector,
    :int8_vector
  ]

  @type live_state ::
          nil
          | %{
              required(:schema) => Schema.t(),
              optional(:indexes) => [IndexDescription.t()],
              optional(:collection_props) => keyword()
            }

  @type t :: %__MODULE__{
          module: module(),
          collection_name: String.t(),
          prefix: String.t() | nil,
          operations: [Operation.t()],
          milvus_version: String.t()
        }

  defstruct [:module, :collection_name, :prefix, :operations, :milvus_version]

  @doc """
  Computes the diff for one (module, prefix) tuple against the live state on the
  given Milvus version.
  """
  @spec diff(module(), String.t() | nil, live_state(), String.t()) :: t()
  def diff(module, prefix, live_state, milvus_version) do
    base_name = Milvex.Collection.collection_name(module)
    full_name = (prefix || "") <> base_name
    expected_schema = %{Milvex.Collection.to_schema(module) | name: full_name}
    expected_indexes = expected_index_config(module)

    operations =
      case live_state do
        nil ->
          [build_create_collection(full_name, expected_schema, milvus_version)] ++
            Enum.map(
              expected_indexes,
              &build_create_index(full_name, &1, milvus_version)
            )

        %{schema: %Schema{} = live_schema} = state ->
          live_indexes = Map.get(state, :indexes, [])

          field_ops(full_name, expected_schema, live_schema, milvus_version) ++
            function_ops(full_name, expected_schema, live_schema, milvus_version) ++
            index_ops(full_name, expected_indexes, live_indexes, milvus_version) ++
            description_ops(full_name, expected_schema, live_schema, milvus_version)
      end
      |> order_operations()

    %__MODULE__{
      module: module,
      collection_name: full_name,
      prefix: prefix,
      operations: operations,
      milvus_version: milvus_version
    }
  end

  @operation_order %{
    create_collection: 0,
    add_field: 1,
    alter_field: 2,
    add_function: 3,
    alter_function: 4,
    create_index: 5,
    recreate_index: 6,
    description_change: 7,
    drop_index: 8,
    drop_function: 9,
    drop_field: 10
  }

  defp order_operations(operations) do
    Enum.sort_by(operations, &Map.fetch!(@operation_order, &1.kind))
  end

  @doc """
  Field-only diff between two `%Schema{}` values.

  Returns the same `%Operation{}` shapes as `diff/4` but limited to field
  add/drop/alter changes. Description-only changes and function/index/KV
  differences are ignored.

  Used by `Milvex.Schema.Migration` to project structural field differences
  into the legacy `{missing, extra, mismatches}` shape without spinning up a
  full DSL module diff.
  """
  @spec field_diff(Schema.t(), Schema.t()) :: [Operation.t()]
  def field_diff(%Schema{name: name} = expected, %Schema{} = live) when is_binary(name) do
    field_ops(name, expected, live, "2.6.0")
  end

  defp field_ops(name, expected, live, ver) do
    expected_fields = Map.new(expected.fields, &{&1.name, &1})
    live_fields = Map.new(live.fields, &{&1.name, &1})

    add_ops =
      expected_fields
      |> Map.drop(Map.keys(live_fields))
      |> Enum.map(fn {_, field} -> classify_add_field(name, field, ver) end)

    drop_ops =
      live_fields
      |> Map.drop(Map.keys(expected_fields))
      |> Enum.map(fn {field_name, _} -> classify_drop_field(name, field_name, ver) end)

    alter_ops =
      expected_fields
      |> Map.keys()
      |> Enum.filter(&Map.has_key?(live_fields, &1))
      |> Enum.flat_map(fn field_name ->
        classify_field_diff(name, expected_fields[field_name], live_fields[field_name], ver)
      end)

    add_ops ++ alter_ops ++ drop_ops
  end

  defp classify_add_field(name, %Field{is_primary_key: true} = field, ver) do
    Operation.build(:add_field, :impossible, name, %{field: field}, ver,
      reason:
        "primary key fields cannot be added to an existing collection; " <>
          "recreate the collection manually"
    )
  end

  defp classify_add_field(name, %Field{data_type: dt} = field, ver) when dt in @vector_types do
    Operation.build(:add_field, :impossible, name, %{field: field}, ver,
      reason:
        "vector fields cannot be added to an existing collection; " <>
          "recreate the collection manually"
    )
  end

  defp classify_add_field(name, %Field{nullable: false, default_value: nil} = field, ver) do
    Operation.build(:add_field, :impossible, name, %{field: field}, ver,
      reason:
        "field '#{field.name}' is not nullable and has no default; existing rows would " <>
          "have no value. Make it nullable, give it a default, or recreate the collection."
    )
  end

  defp classify_add_field(name, field, ver) do
    Operation.build(:add_field, :additive, name, %{field: field}, ver)
  end

  defp classify_drop_field(name, field_name, ver) do
    threshold = MigrationVersion.drop_field_supported_at()

    case Version.compare(MigrationVersion.coerce(ver), threshold) do
      :lt ->
        Operation.build(
          :drop_field,
          :impossible,
          name,
          %{field_name: field_name},
          ver,
          reason:
            "Milvus version #{ver} does not support dropping fields. " <>
              "Upgrade to #{threshold}+ or recreate the collection."
        )

      _ ->
        Operation.build(:drop_field, :destructive, name, %{field_name: field_name}, ver)
    end
  end

  defp classify_field_diff(name, expected, live, ver) do
    case impossible_alter_reason(expected, live) do
      nil -> property_alter_ops(name, expected, live, ver)
      reason -> [impossible_field_change(name, expected, live, ver, reason)]
    end
  end

  defp impossible_alter_reason(expected, live) do
    Enum.find_value(impossible_alter_checks(), fn {check, reason} ->
      if check.(expected, live), do: reason.(expected, live)
    end)
  end

  defp impossible_alter_checks do
    [
      {fn e, l -> e.data_type != l.data_type end,
       fn e, l -> "data type cannot be altered (#{l.data_type} -> #{e.data_type})" end},
      {fn e, l -> array?(e) and e.element_type != l.element_type end,
       fn e, l ->
         "array element_type cannot be altered (#{l.element_type} -> #{e.element_type})"
       end},
      {fn e, l -> array?(e) and e.max_capacity != l.max_capacity end,
       fn e, l ->
         "array max_capacity cannot be altered (#{l.max_capacity} -> #{e.max_capacity})"
       end},
      {fn e, l -> vector?(e) and e.dimension != l.dimension end,
       fn _e, _l ->
         "vector dimension cannot be altered. To change dimension you must " <>
           "create a new collection, re-embed your data, copy, and atomically " <>
           "swap (RenameCollection). Milvex does not automate this."
       end},
      {fn e, l -> e.is_primary_key != l.is_primary_key or e.auto_id != l.auto_id end,
       fn _e, _l -> "primary key / auto_id cannot be altered" end},
      {fn e, l -> e.is_partition_key != l.is_partition_key end,
       fn _e, _l -> "partition_key is set at creation time and cannot be altered" end},
      {fn e, l -> e.is_clustering_key != l.is_clustering_key end,
       fn _e, _l -> "clustering_key is set at creation time and cannot be altered" end}
    ]
  end

  defp property_alter_ops(name, expected, live, ver) do
    max_length_ops(name, expected, live, ver) ++
      nullable_ops(name, expected, live, ver)
  end

  defp max_length_ops(name, expected, live, ver) do
    cond do
      is_nil(expected.max_length) or is_nil(live.max_length) ->
        []

      expected.max_length == live.max_length ->
        []

      expected.max_length > live.max_length ->
        [
          Operation.build(
            :alter_field,
            :additive,
            name,
            %{
              field_name: expected.name,
              changes: %{max_length: [live.max_length, expected.max_length]}
            },
            ver
          )
        ]

      true ->
        [
          Operation.build(
            :alter_field,
            :impossible,
            name,
            %{
              field_name: expected.name,
              changes: %{max_length: [live.max_length, expected.max_length]}
            },
            ver,
            reason:
              "shrinking max_length (#{live.max_length} -> #{expected.max_length}) could " <>
                "truncate existing data; widen instead, or recreate the collection"
          )
        ]
    end
  end

  defp nullable_ops(name, %{nullable: false} = e, %{nullable: true}, ver) do
    [
      Operation.build(
        :alter_field,
        :impossible,
        name,
        %{field_name: e.name, changes: %{nullable: [true, false]}},
        ver,
        reason: "tightening nullable (true -> false) would invalidate existing nulls"
      )
    ]
  end

  defp nullable_ops(name, %{nullable: true} = e, %{nullable: false}, ver) do
    [
      Operation.build(
        :alter_field,
        :additive,
        name,
        %{field_name: e.name, changes: %{nullable: [false, true]}},
        ver
      )
    ]
  end

  defp nullable_ops(_, _, _, _), do: []

  defp index_ops(name, expected_indexes, live_indexes, ver) do
    expected = Map.new(expected_indexes, &{&1.field_name, &1})
    live = Map.new(live_indexes, &{&1.field_name, &1})

    creates =
      expected
      |> Map.drop(Map.keys(live))
      |> Enum.map(fn {_, idx} ->
        Operation.build(:create_index, :additive, name, %{index: idx}, ver)
      end)

    drops =
      live
      |> Map.drop(Map.keys(expected))
      |> Enum.map(fn {field, idx} ->
        Operation.build(
          :drop_index,
          :destructive,
          name,
          %{field_name: field, index_name: idx.index_name},
          ver
        )
      end)

    diffs =
      expected
      |> Map.keys()
      |> Enum.filter(&Map.has_key?(live, &1))
      |> Enum.flat_map(fn field ->
        classify_index_diff(name, expected[field], live[field], ver)
      end)

    creates ++ diffs ++ drops
  end

  defp classify_index_diff(name, %Index{} = exp, live, ver) do
    if structural_index_change?(exp, live) do
      [
        Operation.build(
          :recreate_index,
          :destructive,
          name,
          %{
            field_name: exp.field_name,
            old: index_summary(live),
            new: index_summary(exp),
            dsl_index: exp
          },
          ver
        )
      ]
    else
      []
    end
  end

  defp structural_index_change?(%Index{} = exp, live) do
    live_params = live_params_to_map(live)

    normalize(exp.index_type) != Map.get(live_params, "index_type") or
      normalize(exp.metric_type) != Map.get(live_params, "metric_type") or
      structural_params_differ?(exp, live_params)
  end

  defp structural_params_differ?(%Index{index_type: :hnsw} = exp, live) do
    to_string(exp.params[:M]) != Map.get(live, "M") or
      to_string(exp.params[:efConstruction]) != Map.get(live, "efConstruction")
  end

  defp structural_params_differ?(%Index{index_type: t} = exp, live)
       when t in [:ivf_flat, :ivf_sq8, :scann] do
    to_string(exp.params[:nlist]) != Map.get(live, "nlist")
  end

  defp structural_params_differ?(%Index{index_type: :ivf_pq} = exp, live) do
    to_string(exp.params[:nlist]) != Map.get(live, "nlist") or
      to_string(exp.params[:m]) != Map.get(live, "m") or
      to_string(exp.params[:nbits]) != Map.get(live, "nbits")
  end

  defp structural_params_differ?(_, _), do: false

  defp normalize(nil), do: nil
  defp normalize(atom) when is_atom(atom), do: atom |> Atom.to_string() |> String.upcase()
  defp normalize(str) when is_binary(str), do: String.upcase(str)

  defp live_params_to_map(%IndexDescription{params: params}) when is_list(params) do
    Map.new(params, fn %KeyValuePair{key: k, value: v} -> {k, v} end)
  end

  defp live_params_to_map(%{params: params}) when is_list(params) do
    Map.new(params, fn
      %KeyValuePair{key: k, value: v} -> {k, v}
      %{key: k, value: v} -> {k, v}
    end)
  end

  defp live_params_to_map(_), do: %{}

  @doc """
  Returns a canonical, JSON-friendly summary of an index for use in
  `:recreate_index` payloads.

  Both the DSL (`%Index{}`) and the live (`%IndexDescription{}`) inputs are
  normalised to the same shape:

      %{
        index_type: "HNSW",
        metric_type: "COSINE",
        params: %{M: 16, efConstruction: 256}
      }

  - `index_type` and `metric_type` are upper-case strings (or `nil`).
  - Structural integer params (`M`, `efConstruction`, `nlist`, `m`, `nbits`)
    are always atom-keyed and integer-typed regardless of source.
  - On the live side, unknown params are dropped; the structural ones are
    parsed via `String.to_integer/1`.
  """
  @spec index_summary(Index.t() | IndexDescription.t() | map()) :: map()
  def index_summary(%Index{} = idx) do
    %{
      index_type: normalize(idx.index_type),
      metric_type: normalize(idx.metric_type),
      params: canonicalize_dsl_params(idx.params)
    }
  end

  def index_summary(%IndexDescription{} = desc) do
    params = live_params_to_map(desc)

    %{
      index_type: Map.get(params, "index_type"),
      metric_type: Map.get(params, "metric_type"),
      params: canonicalize_live_params(params)
    }
  end

  def index_summary(other) when is_map(other), do: other

  defp canonicalize_dsl_params(params) when is_map(params) do
    Enum.reduce(params, %{}, fn {k, v}, acc ->
      key = if is_atom(k), do: k, else: safe_atom(k)

      cond do
        key in @structural_int_param_keys -> Map.put(acc, key, to_integer(v))
        is_atom(key) -> Map.put(acc, key, v)
        true -> acc
      end
    end)
  end

  defp canonicalize_dsl_params(_), do: %{}

  defp canonicalize_live_params(params) do
    params
    |> Map.drop(["index_type", "metric_type"])
    |> Enum.reduce(%{}, fn {k, v}, acc ->
      if k in @structural_int_param_strings do
        Map.put(acc, String.to_existing_atom(k), to_integer(v))
      else
        acc
      end
    end)
  end

  defp safe_atom(str) when is_binary(str) do
    String.to_existing_atom(str)
  rescue
    ArgumentError -> nil
  end

  defp to_integer(v) when is_integer(v), do: v

  defp to_integer(v) when is_binary(v) do
    case Integer.parse(v) do
      {int, ""} -> int
      _ -> v
    end
  end

  defp to_integer(v), do: v

  defp function_ops(name, expected, live, ver) do
    expected_fns = Map.new(expected.functions, &{&1.name, &1})
    live_fns = Map.new(live.functions, &{&1.name, &1})

    adds =
      expected_fns
      |> Map.drop(Map.keys(live_fns))
      |> Enum.map(fn {_, fun} ->
        Operation.build(:add_function, :additive, name, %{function: fun}, ver)
      end)

    drops =
      live_fns
      |> Map.drop(Map.keys(expected_fns))
      |> Enum.map(fn {fn_name, _} ->
        Operation.build(:drop_function, :destructive, name, %{function_name: fn_name}, ver)
      end)

    alters =
      expected_fns
      |> Map.keys()
      |> Enum.filter(&Map.has_key?(live_fns, &1))
      |> Enum.flat_map(fn fn_name ->
        classify_function_diff(name, expected_fns[fn_name], live_fns[fn_name], ver)
      end)

    adds ++ alters ++ drops
  end

  defp classify_function_diff(name, %Function{} = exp, %Function{} = live, ver) do
    changes = function_changes(exp, live)

    if map_size(changes) == 0 do
      []
    else
      [
        Operation.build(
          :alter_function,
          :additive,
          name,
          %{function_name: exp.name, changes: changes, dsl_function: exp},
          ver
        )
      ]
    end
  end

  defp function_changes(%Function{} = exp, %Function{} = live) do
    %{}
    |> diff_put(:type, live.type, exp.type)
    |> diff_put(:input_field_names, live.input_field_names, exp.input_field_names)
    |> diff_put(:output_field_names, live.output_field_names, exp.output_field_names)
    |> diff_put(:params, live.params, exp.params)
  end

  defp diff_put(map, _key, same, same), do: map
  defp diff_put(map, key, old, new), do: Map.put(map, key, [old, new])

  defp description_ops(name, expected, live, ver) do
    live_index = Map.new(live.fields, &{&1.name, &1})

    Enum.flat_map(expected.fields, &description_op_for(&1, live_index, name, ver))
  end

  defp description_op_for(%Field{} = expected, live_index, name, ver) do
    case Map.get(live_index, expected.name) do
      nil -> []
      %Field{} = live -> description_change(expected, live, name, ver)
    end
  end

  defp description_change(%Field{} = expected, %Field{} = live, name, ver) do
    expected_desc = expected.description || ""
    live_desc = live.description || ""

    if expected_desc == live_desc do
      []
    else
      [
        Operation.build(
          :description_change,
          :descriptive,
          name,
          %{field_name: expected.name, from: live_desc, to: expected_desc},
          ver
        )
      ]
    end
  end

  defp build_create_collection(name, schema, ver) do
    Operation.build(:create_collection, :additive, name, %{schema: schema}, ver)
  end

  defp build_create_index(name, idx, ver) do
    Operation.build(:create_index, :additive, name, %{index: idx}, ver)
  end

  defp expected_index_config(module) do
    if Code.ensure_loaded?(module) and function_exported?(module, :index_config, 0) do
      module.index_config()
    else
      []
    end
  end

  defp impossible_field_change(name, expected, live, ver, reason) do
    Operation.build(
      :alter_field,
      :impossible,
      name,
      %{
        field_name: expected.name,
        expected: field_summary(expected),
        live: field_summary(live)
      },
      ver,
      reason: reason
    )
  end

  defp vector?(%{data_type: dt}), do: dt in @vector_types

  defp array?(%{data_type: :array}), do: true
  defp array?(_), do: false

  defp field_summary(%Field{} = f) do
    %{
      data_type: f.data_type,
      dimension: f.dimension,
      max_length: f.max_length,
      nullable: f.nullable,
      is_primary_key: f.is_primary_key,
      auto_id: f.auto_id,
      is_partition_key: f.is_partition_key,
      is_clustering_key: f.is_clustering_key
    }
  end
end
