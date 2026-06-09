defmodule Milvex.Migration.CLI do
  @moduledoc """
  Layered, halt-free entry point for `mix milvex.migrate`.

  Parses argv, validates flags, resolves modules / prefixes, computes plans
  via `Milvex.Migration.Plan.diff/4`, optionally applies them via
  `Milvex.Migration.Runner.apply/2`, and renders output via
  `Milvex.Migration.Reporter.render/2`.

  Returns `{exit_code, iodata}`. Never calls `System.halt/1`. The Mix task
  wraps this and is responsible for halting.

  ## Exit code priority hierarchy

  When multiple conditions could apply, the higher number wins (1 > 2 > 4 > 3 > 0):

    * 0 — clean
    * 1 — configuration / argv error
    * 2 — at least one impossible op present (plan mode); apply blocked by impossible
    * 3 — destructive ops present without `--allow-drop` (plan mode); skipped by runner (apply mode)
    * 4 — at least one RPC failure during apply; describe_collection error during plan computation

  ## Dependency injection

  Callers may pass `fetch_config_fn` and `connect_fn` to override the defaults.
  This is used in tests to avoid touching real Application env or live
  processes.
  """

  alias Milvex.Migration.Plan
  alias Milvex.Migration.Reporter
  alias Milvex.Migration.Runner
  alias Milvex.Migration.Runner.ApplyReport
  alias Milvex.Migration.Runner.Context

  @flag_specs [
    plan: :boolean,
    apply: :boolean,
    allow_drop: :boolean,
    manage_load: :boolean,
    module: :keep,
    prefix: :keep,
    format: :string,
    connection: :string,
    verbose: :boolean,
    quiet: :boolean
  ]

  @flag_aliases [v: :verbose, q: :quiet]

  @usage "Usage: mix milvex.migrate (--plan | --apply) [options]"

  @type fetch_config_fn :: (atom(), atom() -> term())
  @type connect_fn :: (atom() | nil -> {:ok, GenServer.server()} | {:error, term()})

  @type opts :: %{
          mode: :plan | :apply,
          allow_drop: boolean(),
          manage_load: boolean(),
          modules: [String.t()],
          prefixes: [String.t()],
          format: :text | :json,
          connection: String.t() | nil,
          verbose: boolean(),
          quiet: boolean()
        }

  @spec run([String.t()], fetch_config_fn(), connect_fn()) :: {0..4, iodata()}
  def run(argv, fetch_config_fn \\ &Application.get_env/2, connect_fn \\ &default_connect/1) do
    with {:ok, opts} <- parse_argv(argv),
         {:ok, modules} <- resolve_modules(opts, fetch_config_fn),
         {:ok, prefixes} <- resolve_prefixes(opts, fetch_config_fn),
         {:ok, conn_name} <- connection_name(opts, fetch_config_fn),
         {:ok, conn} <- connect_fn.(conn_name),
         {:ok, version} <- fetch_version(conn),
         {:ok, plans} <- compute_plans(cartesian(modules, prefixes), conn, version) do
      run_mode(opts, plans, conn)
    else
      {:error, code, io} when is_integer(code) -> {code, io}
      {:error, reason} -> {1, error_message(reason)}
      {:error, tag, info} -> error_tuple_to_result(tag, info)
      {:error, tag, info1, info2} -> error_tuple_to_result(tag, info1, info2)
    end
  end

  defp parse_argv(argv) do
    {parsed, _rest, invalid} =
      OptionParser.parse(argv, strict: @flag_specs, aliases: @flag_aliases)

    case invalid do
      [] -> validate_parsed(parsed)
      [{flag, _} | _] -> {:error, {:invalid_flag, flag}}
    end
  end

  defp validate_parsed(parsed) do
    plan? = Keyword.get(parsed, :plan, false)
    apply? = Keyword.get(parsed, :apply, false)

    cond do
      plan? and apply? -> {:error, :conflicting_modes}
      not plan? and not apply? -> {:error, :missing_mode}
      true -> build_opts(parsed, if(plan?, do: :plan, else: :apply))
    end
  end

  defp build_opts(parsed, mode) do
    with {:ok, format} <- parse_format(Keyword.get(parsed, :format)) do
      modules = Keyword.get_values(parsed, :module)
      prefixes = Keyword.get_values(parsed, :prefix)

      {:ok,
       %{
         mode: mode,
         allow_drop: Keyword.get(parsed, :allow_drop, false),
         manage_load: Keyword.get(parsed, :manage_load, false),
         modules: modules,
         prefixes: prefixes,
         format: format,
         connection: Keyword.get(parsed, :connection),
         verbose: Keyword.get(parsed, :verbose, false),
         quiet: Keyword.get(parsed, :quiet, false)
       }}
    end
  end

  defp parse_format(nil), do: {:ok, :text}
  defp parse_format("text"), do: {:ok, :text}
  defp parse_format("json"), do: {:ok, :json}
  defp parse_format(other), do: {:error, {:unknown_format, other}}

  defp resolve_modules(%{modules: []}, fetch_config_fn) do
    config = fetch_config_fn.(:milvex, :migrate) || []

    case Keyword.get(config, :collections, []) do
      [] -> {:error, :no_modules}
      list when is_list(list) -> {:ok, list}
    end
  end

  defp resolve_modules(%{modules: modules}, _fetch_config_fn) do
    Enum.reduce_while(modules, {:ok, []}, fn name, {:ok, acc} ->
      module = Module.concat([name])

      if Code.ensure_loaded?(module) do
        {:cont, {:ok, acc ++ [module]}}
      else
        {:halt, {:error, {:unknown_module, name}}}
      end
    end)
  end

  defp resolve_prefixes(%{prefixes: []}, fetch_config_fn) do
    config = fetch_config_fn.(:milvex, :migrate) || []

    case Keyword.get(config, :prefix_resolver) do
      nil -> {:ok, [nil]}
      {m, f, a} -> {:ok, apply(m, f, a)}
    end
  end

  defp resolve_prefixes(%{prefixes: prefixes}, _fetch_config_fn), do: {:ok, prefixes}

  defp connection_name(%{connection: nil}, fetch_config_fn) do
    config = fetch_config_fn.(:milvex, :migrate) || []
    {:ok, Keyword.get(config, :connection)}
  end

  defp connection_name(%{connection: name}, _fetch_config_fn) when is_binary(name) do
    {:ok, String.to_atom(name)}
  end

  defp fetch_version(conn) do
    case Milvex.get_version(conn, []) do
      {:ok, version} -> {:ok, version}
      {:error, reason} -> {:error, :version_failed, reason}
    end
  end

  defp cartesian(modules, prefixes) do
    for m <- modules, p <- prefixes, do: {m, p}
  end

  defp compute_plans(tuples, conn, version) do
    Enum.reduce_while(tuples, {:ok, []}, fn {module, prefix}, {:ok, acc} ->
      case compute_plan(module, prefix, conn, version) do
        {:ok, plan} -> {:cont, {:ok, acc ++ [plan]}}
        {:error, _, _, _} = err -> {:halt, err}
      end
    end)
  end

  defp compute_plan(module, prefix, conn, version) do
    base_name = Milvex.Collection.collection_name(module)
    full_name = (prefix || "") <> base_name

    case Milvex.has_collection(conn, full_name, []) do
      {:ok, false} ->
        {:ok, Plan.diff(module, prefix, nil, version)}

      {:ok, true} ->
        with {:ok, info} <- Milvex.describe_collection(conn, full_name, []),
             {:ok, indexes} <- describe_index_or_empty(conn, full_name) do
          live_state = %{schema: info.schema, indexes: indexes, collection_props: []}
          {:ok, Plan.diff(module, prefix, live_state, version)}
        else
          {:error, reason} -> {:error, :describe_failed, full_name, reason}
        end

      {:error, reason} ->
        {:error, :describe_failed, full_name, reason}
    end
  end

  defp describe_index_or_empty(conn, name) do
    case Milvex.describe_index(conn, name, []) do
      {:ok, indexes} -> {:ok, indexes}
      {:error, _} -> {:ok, []}
    end
  end

  defp run_mode(%{mode: :plan} = opts, plans, _conn) do
    io = Reporter.render(plans, format: opts.format, verbose: opts.verbose)
    {compute_plan_exit_code(plans, opts), io}
  end

  defp run_mode(%{mode: :apply} = opts, plans, conn) do
    ctx = %Context{
      conn: conn,
      version: hd_version(plans),
      allow_drop: opts.allow_drop,
      manage_load: opts.manage_load
    }

    report = Runner.apply(plans, ctx)
    io = Reporter.render(report, format: opts.format, verbose: opts.verbose)
    {compute_apply_exit_code(plans, report, opts), io}
  end

  defp hd_version([%Plan{milvus_version: v} | _]), do: v
  defp hd_version(_), do: ""

  defp compute_plan_exit_code(plans, opts) do
    cond do
      any_op?(plans, :impossible) -> 2
      not opts.allow_drop and any_op?(plans, :destructive) -> 3
      true -> 0
    end
  end

  defp compute_apply_exit_code(_plans, %ApplyReport{} = report, opts) do
    cond do
      report.blocked_by_impossible -> 2
      report.counts.failed > 0 -> 4
      load_failed?(report) -> 4
      not opts.allow_drop and report.counts.skipped_destructive > 0 -> 3
      true -> 0
    end
  end

  defp load_failed?(%ApplyReport{plan_results: plan_results}) do
    Enum.any?(plan_results, fn
      %{load_status: {:release_failed, _}} -> true
      %{load_status: {:reload_failed, _}} -> true
      _ -> false
    end)
  end

  defp any_op?(plans, category) do
    Enum.any?(plans, fn %Plan{operations: ops} ->
      Enum.any?(ops, &(&1.category == category))
    end)
  end

  defp error_tuple_to_result(:describe_failed, name, reason) do
    {4,
     [
       "describe failed for collection: ",
       name,
       " (",
       inspect(reason),
       ")\n",
       @usage,
       "\n"
     ]}
  end

  defp error_tuple_to_result(:connect_failed, reason) do
    {1, ["could not acquire connection: ", inspect(reason), "\n", @usage, "\n"]}
  end

  defp error_tuple_to_result(:version_failed, reason) do
    {1, ["could not fetch Milvus version: ", inspect(reason), "\n", @usage, "\n"]}
  end

  defp error_tuple_to_result(tag, info) do
    {1, [error_message({tag, info}), "\n", @usage, "\n"]}
  end

  defp error_message(:missing_mode) do
    ["specify --plan or --apply\n", @usage, "\n"]
  end

  defp error_message(:conflicting_modes) do
    ["--plan and --apply are mutually exclusive\n", @usage, "\n"]
  end

  defp error_message(:no_modules) do
    [
      "no collections configured (config :milvex, :migrate, :collections)\n",
      @usage,
      "\n"
    ]
  end

  defp error_message(:no_connection) do
    ["no :connection configured\n", @usage, "\n"]
  end

  defp error_message({:unknown_module, name}) do
    ["unknown module: ", name, "\n", @usage, "\n"]
  end

  defp error_message({:unknown_format, format}) do
    ["unknown --format: ", inspect(format), "\n", @usage, "\n"]
  end

  defp error_message({:invalid_flag, flag}) do
    ["invalid flag: ", flag, "\n", @usage, "\n"]
  end

  defp error_message(other) do
    ["error: ", inspect(other), "\n", @usage, "\n"]
  end

  defp default_connect(nil), do: {:error, :no_connection}

  defp default_connect(name) do
    deadline = System.monotonic_time(:millisecond) + 5_000

    if wait_alive(name, deadline) do
      {:ok, name}
    else
      {:error, :connect_failed, "process #{inspect(name)} not alive after 5s"}
    end
  end

  defp wait_alive(name, deadline) do
    cond do
      Process.whereis(name) ->
        true

      System.monotonic_time(:millisecond) >= deadline ->
        false

      true ->
        Process.sleep(100)
        wait_alive(name, deadline)
    end
  end
end
