defmodule Milvex.Migration.Runner do
  @moduledoc """
  Applies a list of `%Milvex.Migration.Plan{}` against a live Milvus cluster.

  The runner is the only module in the migration pipeline that issues mutating
  RPCs. It walks the plans sequentially and applies each operation per the
  rules in `apply/2`:

    * If any plan in the batch contains an `:impossible` operation, the runner
      returns immediately. No RPC is attempted; every non-impossible operation
      across all plans is reported as `:blocked_by_impossible` and every
      `:impossible` op as `:blocked_impossible`.
    * For each plan, when `manage_load: true` AND any operation in that plan
      requires release AND the live collection is loaded, the runner releases
      the collection before applying the operations and re-loads it after.
    * Operations are applied in plan order. `:additive` ops always run.
      `:destructive` ops run only when `allow_drop: true`; otherwise they are
      `:skipped_no_flag`. `:descriptive` ops always come back as
      `:skipped_idempotent` and never go through the dispatch path.
    * Per-operation RPC failures DO NOT abort the plan. The failure is recorded
      and the runner moves on to the next op. Release / reload failures DO
      abort the plan (no further ops attempted on release failure; ops up to
      the failure point are kept on reload failure).
    * Plans are isolated. A failure in one plan never leaks load state to the
      next plan.

  The runner emits `:telemetry` spans:

    * Run-level: `[:milvex, :migrate, :run, :start | :stop | :exception]` with
      start metadata `%{mode, allow_drop, manage_load}` and stop metadata
      `%{summary: counts}`.
    * Op-level: `[:milvex, :migrate, :op, :start | :stop | :exception]` with
      start metadata
      `%{kind, category, collection_name, module, requires_release, milvus_version}`
      and stop metadata `%{result: status}`. Only operations that actually
      reach the dispatch path emit telemetry; skipped/blocked ops do not.
  """

  alias Milvex.Migration.Operation
  alias Milvex.Migration.Plan
  alias Milvex.Migration.Version, as: MigrationVersion

  defmodule Context do
    @moduledoc """
    Inputs handed to `Runner.apply/2`: the connection, the Milvus version,
    and the apply-mode flags.
    """

    @type t :: %__MODULE__{
            conn: GenServer.server(),
            version: String.t(),
            allow_drop: boolean(),
            manage_load: boolean()
          }

    defstruct [:conn, :version, :allow_drop, :manage_load]
  end

  defmodule OpResult do
    @moduledoc """
    Outcome of attempting one operation: the operation itself plus its terminal
    status. `:ok` means the dispatched RPC succeeded; the various skip atoms
    mean the dispatch path was not entered.
    """

    @type status ::
            :ok
            | :skipped_no_flag
            | :skipped_idempotent
            | :blocked_by_impossible
            | :blocked_impossible
            | {:error, term()}

    @type t :: %__MODULE__{operation: Operation.t(), status: status()}

    defstruct [:operation, :status]
  end

  defmodule PlanResult do
    @moduledoc """
    Aggregated result for one plan: every operation's `OpResult` plus the
    load-management status describing what the runner did (or chose not to do)
    around release/reload.
    """

    @type load_status ::
            :unmanaged
            | :no_release_needed
            | :was_not_loaded
            | :released_and_reloaded
            | {:release_failed, term()}
            | {:reload_failed, term()}

    @type t :: %__MODULE__{
            plan: Plan.t(),
            op_results: [OpResult.t()],
            load_status: load_status()
          }

    defstruct [:plan, :op_results, :load_status]
  end

  defmodule ApplyReport do
    @moduledoc """
    Final report from one `Runner.apply/2` call: per-plan results, a flag
    telling whether the run was short-circuited by an `:impossible` op, and
    aggregate counts.
    """

    @type counts :: %{
            applied: non_neg_integer(),
            skipped_destructive: non_neg_integer(),
            skipped_idempotent: non_neg_integer(),
            failed: non_neg_integer(),
            blocked: non_neg_integer(),
            impossible: non_neg_integer()
          }

    @type t :: %__MODULE__{
            plan_results: [PlanResult.t()],
            blocked_by_impossible: boolean(),
            counts: counts()
          }

    defstruct plan_results: [],
              blocked_by_impossible: false,
              counts: %{
                applied: 0,
                skipped_destructive: 0,
                skipped_idempotent: 0,
                failed: 0,
                blocked: 0,
                impossible: 0
              }
  end

  @doc """
  Applies the given plans against the connection captured in `ctx`.

  See the moduledoc for the full set of rules. Returns an `%ApplyReport{}`.
  """
  @spec apply([Plan.t()], Context.t()) :: ApplyReport.t()
  def apply(plans, %Context{} = ctx) when is_list(plans) do
    case detect_impossible(plans) do
      true ->
        build_blocked_report(plans)

      false ->
        :telemetry.span(
          [:milvex, :migrate, :run],
          %{mode: :apply, allow_drop: ctx.allow_drop, manage_load: ctx.manage_load},
          fn ->
            report = run_plans(plans, ctx)
            {report, %{summary: report.counts}}
          end
        )
    end
  end

  defp detect_impossible(plans) do
    Enum.any?(plans, fn %Plan{operations: ops} ->
      Enum.any?(ops, &(&1.category == :impossible))
    end)
  end

  defp build_blocked_report(plans) do
    plan_results = Enum.map(plans, &blocked_plan_result/1)

    counts =
      plan_results
      |> Enum.flat_map(& &1.op_results)
      |> Enum.reduce(blank_counts(), &count_blocked/2)

    %ApplyReport{
      plan_results: plan_results,
      blocked_by_impossible: true,
      counts: counts
    }
  end

  defp blocked_plan_result(%Plan{} = plan) do
    op_results = Enum.map(plan.operations, &blocked_op_result/1)
    %PlanResult{plan: plan, op_results: op_results, load_status: :unmanaged}
  end

  defp blocked_op_result(%Operation{category: :impossible} = op),
    do: %OpResult{operation: op, status: :blocked_impossible}

  defp blocked_op_result(%Operation{} = op),
    do: %OpResult{operation: op, status: :blocked_by_impossible}

  defp count_blocked(%OpResult{status: :blocked_impossible}, c),
    do: Map.update!(c, :impossible, &(&1 + 1))

  defp count_blocked(%OpResult{status: :blocked_by_impossible}, c),
    do: Map.update!(c, :blocked, &(&1 + 1))

  defp run_plans(plans, ctx) do
    Enum.reduce(plans, %ApplyReport{}, fn plan, acc ->
      plan_result = run_plan(plan, ctx)
      merge_plan_result(acc, plan_result)
    end)
  end

  defp run_plan(%Plan{} = plan, ctx) do
    case maybe_release(plan, ctx) do
      {:ok, load_state} ->
        op_results = Enum.map(plan.operations, &run_one(&1, plan, ctx))
        load_status = maybe_reload(load_state, plan, ctx)
        %PlanResult{plan: plan, op_results: op_results, load_status: load_status}

      {:error, :release_failed, reason} ->
        %PlanResult{plan: plan, op_results: [], load_status: {:release_failed, reason}}
    end
  end

  defp maybe_release(%Plan{} = _plan, %Context{manage_load: false}), do: {:ok, :unmanaged}

  defp maybe_release(
         %Plan{operations: ops, collection_name: name},
         %Context{manage_load: true} = ctx
       ) do
    if Enum.any?(ops, & &1.requires_release) do
      release_if_loaded(ctx.conn, name)
    else
      {:ok, :no_release_needed}
    end
  end

  defp release_if_loaded(conn, name) do
    case Milvex.get_load_state(conn, name, []) do
      {:ok, :loaded} -> do_release(conn, name)
      {:ok, _other} -> {:ok, :was_not_loaded}
      {:error, reason} -> {:error, :release_failed, reason}
    end
  end

  defp do_release(conn, name) do
    case Milvex.release_collection(conn, name) do
      :ok -> {:ok, :was_loaded}
      {:error, reason} -> {:error, :release_failed, reason}
    end
  end

  defp maybe_reload(:unmanaged, _plan, _ctx), do: :unmanaged
  defp maybe_reload(:no_release_needed, _plan, _ctx), do: :no_release_needed
  defp maybe_reload(:was_not_loaded, _plan, _ctx), do: :was_not_loaded

  defp maybe_reload(:was_loaded, %Plan{collection_name: name}, %Context{conn: conn}) do
    case Milvex.load_collection(conn, name) do
      :ok -> :released_and_reloaded
      {:error, reason} -> {:reload_failed, reason}
    end
  end

  defp run_one(%Operation{category: :destructive} = op, _plan, %Context{allow_drop: false}) do
    %OpResult{operation: op, status: :skipped_no_flag}
  end

  defp run_one(%Operation{category: :descriptive} = op, _plan, _ctx) do
    %OpResult{operation: op, status: :skipped_idempotent}
  end

  defp run_one(%Operation{} = op, %Plan{} = plan, %Context{} = ctx) do
    metadata = %{
      kind: op.kind,
      category: op.category,
      collection_name: op.collection_name,
      module: plan.module,
      requires_release: op.requires_release,
      milvus_version: plan.milvus_version
    }

    :telemetry.span(
      [:milvex, :migrate, :op],
      metadata,
      fn ->
        result = dispatch(op, plan, ctx)
        {result, %{result: result.status}}
      end
    )
  end

  defp dispatch(%Operation{kind: :create_collection, payload: %{schema: schema}} = op, _plan, ctx) do
    case Milvex.create_collection(ctx.conn, op.collection_name, schema, []) do
      :ok ->
        %OpResult{operation: op, status: :ok}

      {:error, %{message: msg}} = err ->
        idempotent_or_error(err, op, msg, ~r/collection.*already exists/i)

      {:error, _} = err ->
        error_result(op, err)
    end
  end

  defp dispatch(%Operation{kind: :add_field, payload: %{field: field}} = op, _plan, ctx) do
    if pre_2_6?(ctx.version) do
      Milvex.add_collection_field(ctx.conn, op.collection_name, field, [])
      |> wrap_simple(op)
    else
      Milvex.alter_collection_schema(ctx.conn, op.collection_name, add_fields: [field])
      |> wrap_simple(op)
    end
  end

  defp dispatch(%Operation{kind: :drop_field, payload: %{field_name: name}} = op, _plan, ctx) do
    Milvex.alter_collection_schema(ctx.conn, op.collection_name, drop_fields: [name])
    |> wrap_simple(op)
  end

  defp dispatch(
         %Operation{kind: :alter_field, payload: %{field_name: field_name, changes: changes}} = op,
         _plan,
         ctx
       ) do
    Milvex.alter_collection_field(ctx.conn, op.collection_name, field_name,
      set: changes_to_kv(changes)
    )
    |> wrap_simple(op)
  end

  defp dispatch(%Operation{kind: :create_index, payload: %{index: index}} = op, _plan, ctx) do
    case Milvex.create_index(ctx.conn, op.collection_name, index, []) do
      :ok ->
        %OpResult{operation: op, status: :ok}

      {:error, %{message: msg}} = err ->
        idempotent_or_error(err, op, msg, ~r/index.*(already exists|already created)/i)

      {:error, _} = err ->
        error_result(op, err)
    end
  end

  defp dispatch(%Operation{kind: :drop_index, payload: payload} = op, _plan, ctx) do
    %{field_name: field_name} = payload

    drop_opts =
      if Map.has_key?(payload, :index_name), do: [index_name: payload.index_name], else: []

    Milvex.drop_index(ctx.conn, op.collection_name, field_name, drop_opts)
    |> wrap_simple(op)
  end

  defp dispatch(
         %Operation{
           kind: :recreate_index,
           payload: %{field_name: field_name, dsl_index: dsl_index} = payload
         } = op,
         _plan,
         ctx
       ) do
    drop_opts =
      if Map.has_key?(payload, :index_name), do: [index_name: payload.index_name], else: []

    with :ok <- Milvex.drop_index(ctx.conn, op.collection_name, field_name, drop_opts),
         :ok <- Milvex.create_index(ctx.conn, op.collection_name, dsl_index, []) do
      %OpResult{operation: op, status: :ok}
    else
      {:error, _} = err -> error_result(op, err)
    end
  end

  defp dispatch(
         %Operation{kind: :alter_index, payload: %{index_name: index_name, changes: changes}} = op,
         _plan,
         ctx
       ) do
    Milvex.alter_index(ctx.conn, op.collection_name, index_name, set: changes_to_kv(changes))
    |> wrap_simple(op)
  end

  defp dispatch(%Operation{kind: :add_function, payload: %{function: function}} = op, _plan, ctx) do
    Milvex.add_collection_function(ctx.conn, op.collection_name, function, [])
    |> wrap_simple(op)
  end

  defp dispatch(
         %Operation{kind: :alter_function, payload: %{dsl_function: function}} = op,
         _plan,
         ctx
       ) do
    Milvex.alter_collection_function(ctx.conn, op.collection_name, function, [])
    |> wrap_simple(op)
  end

  defp dispatch(
         %Operation{kind: :drop_function, payload: %{function_name: name}} = op,
         _plan,
         ctx
       ) do
    Milvex.drop_collection_function(ctx.conn, op.collection_name, name, [])
    |> wrap_simple(op)
  end

  defp dispatch(%Operation{kind: :alter_collection, payload: payload} = op, _plan, ctx) do
    opts =
      []
      |> maybe_put(:set, Map.get(payload, :set))
      |> maybe_put(:delete, Map.get(payload, :delete))

    Milvex.alter_collection(ctx.conn, op.collection_name, opts)
    |> wrap_simple(op)
  end

  defp wrap_simple(:ok, op), do: %OpResult{operation: op, status: :ok}
  defp wrap_simple({:error, _} = err, op), do: error_result(op, err)

  defp error_result(op, {:error, reason}), do: %OpResult{operation: op, status: {:error, reason}}

  defp idempotent_or_error({:error, _} = err, op, msg, regex) when is_binary(msg) do
    if Regex.match?(regex, msg) do
      %OpResult{operation: op, status: :skipped_idempotent}
    else
      error_result(op, err)
    end
  end

  defp idempotent_or_error({:error, _} = err, op, _msg, _regex), do: error_result(op, err)

  defp changes_to_kv(changes) when is_map(changes) do
    Enum.map(changes, fn {key, [_old, new]} -> {key, new} end)
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)

  defp pre_2_6?(version) do
    Version.compare(MigrationVersion.coerce(version), MigrationVersion.drop_field_supported_at()) ==
      :lt
  end

  defp merge_plan_result(%ApplyReport{} = report, %PlanResult{} = pr) do
    counts = Enum.reduce(pr.op_results, report.counts, &bump/2)

    %ApplyReport{
      report
      | plan_results: report.plan_results ++ [pr],
        counts: counts
    }
  end

  defp bump(%OpResult{status: :ok}, counts), do: Map.update!(counts, :applied, &(&1 + 1))

  defp bump(%OpResult{status: :skipped_no_flag}, counts),
    do: Map.update!(counts, :skipped_destructive, &(&1 + 1))

  defp bump(%OpResult{status: :skipped_idempotent}, counts),
    do: Map.update!(counts, :skipped_idempotent, &(&1 + 1))

  defp bump(%OpResult{status: {:error, _}}, counts), do: Map.update!(counts, :failed, &(&1 + 1))

  defp bump(%OpResult{status: :blocked_by_impossible}, counts),
    do: Map.update!(counts, :blocked, &(&1 + 1))

  defp bump(%OpResult{status: :blocked_impossible}, counts),
    do: Map.update!(counts, :impossible, &(&1 + 1))

  defp blank_counts do
    %{
      applied: 0,
      skipped_destructive: 0,
      skipped_idempotent: 0,
      failed: 0,
      blocked: 0,
      impossible: 0
    }
  end
end
