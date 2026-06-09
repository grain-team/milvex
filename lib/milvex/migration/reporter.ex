defmodule Milvex.Migration.Reporter do
  @moduledoc """
  Renders migration plans and apply reports as user-facing output.

  Accepts either:

    * a list of `Milvex.Migration.Plan` structs (used by `--plan` mode), or
    * an apply-report struct (used by `--apply` mode) carrying
      `:plan_results`, `:blocked_by_impossible`, and `:counts` fields.

  Two formats are supported via `format: :text | :json`. Both return iodata
  so the caller can write directly to stdout without a binary copy.

  ## Apply-report duck typing

  This module ships ahead of `Milvex.Migration.Runner.ApplyReport` (Task 5).
  Rather than hard-pattern-matching on a not-yet-defined struct, the apply-
  report path matches structurally on `is_struct/1` plus the presence of
  `:plan_results`. Once the Runner lands its struct will satisfy that shape
  unchanged. Each `plan_result` is expected to carry `:plan`, `:op_results`,
  and `:load_status`; each op-result is expected to carry `:operation` and
  `:status`.

  ## verbose option

  The `verbose: bool` option is reserved for future use (e.g. dumping full
  payload diffs). v1 emits the same output regardless. The flag is accepted
  so the CLI can pass it through unchanged once verbose rendering lands.
  """

  alias Milvex.Migration.Operation
  alias Milvex.Migration.Plan

  @spec render([Plan.t()] | struct(), keyword()) :: iodata()
  def render(plans_or_report, opts \\ []) do
    format = Keyword.get(opts, :format, :text)
    verbose = Keyword.get(opts, :verbose, false)
    dispatch(plans_or_report, format, verbose)
  end

  defp dispatch(plans, :text, verbose) when is_list(plans), do: render_plans_text(plans, verbose)
  defp dispatch(plans, :json, verbose) when is_list(plans), do: render_plans_json(plans, verbose)

  defp dispatch(report, :text, verbose) when is_struct(report),
    do: render_report_text(report, verbose)

  defp dispatch(report, :json, verbose) when is_struct(report),
    do: render_report_json(report, verbose)

  defp render_plans_text(plans, _verbose) do
    [
      Enum.map(plans, &render_plan_text/1),
      render_plan_summary_text(plans)
    ]
  end

  defp render_plan_text(%Plan{} = plan) do
    grouped = Enum.group_by(plan.operations, & &1.category)

    [
      "== ",
      inspect(plan.module),
      " → ",
      plan.collection_name,
      " ==\n\n",
      render_group("Additive", grouped[:additive] || [], suffix: ":"),
      render_group("Destructive", grouped[:destructive] || [],
        suffix: " — gated by --allow-drop:"
      ),
      render_group("Descriptive-only", grouped[:descriptive] || [],
        suffix: " (cannot be applied):"
      ),
      render_group("Impossible", grouped[:impossible] || [], suffix: ":", show_reason: true),
      "\n"
    ]
  end

  defp render_group(_label, [], _opts), do: []

  defp render_group(label, ops, opts) do
    suffix = Keyword.get(opts, :suffix, ":")
    show_reason = Keyword.get(opts, :show_reason, false)

    [
      "  ",
      label,
      " (",
      Integer.to_string(length(ops)),
      ")",
      suffix,
      "\n",
      Enum.map(ops, fn op ->
        [
          "    ",
          Operation.to_line(op),
          "\n",
          if(show_reason and op.reason,
            do: ["      reason: ", op.reason, "\n"],
            else: []
          )
        ]
      end),
      "\n"
    ]
  end

  defp render_plan_summary_text(plans) do
    counts = total_counts(plans)

    [
      "== Summary ==\n",
      "  collections inspected:    ",
      Integer.to_string(length(plans)),
      "\n",
      "  collections with changes: ",
      Integer.to_string(Enum.count(plans, &(&1.operations != []))),
      "\n",
      "  operations:               ",
      "additive=",
      Integer.to_string(counts.additive),
      "  destructive=",
      Integer.to_string(counts.destructive),
      "  descriptive=",
      Integer.to_string(counts.descriptive),
      "  impossible=",
      Integer.to_string(counts.impossible),
      "\n"
    ]
  end

  defp total_counts(plans) do
    initial = %{additive: 0, destructive: 0, descriptive: 0, impossible: 0}

    Enum.reduce(plans, initial, fn plan, acc ->
      Enum.reduce(plan.operations, acc, fn op, acc ->
        Map.update!(acc, op.category, &(&1 + 1))
      end)
    end)
  end

  defp render_plans_json(plans, _verbose) do
    counts = total_counts(plans)

    payload = %{
      version: 1,
      mode: "plan",
      collections: Enum.map(plans, &plan_to_json/1),
      summary: %{
        collections_inspected: length(plans),
        collections_with_changes: Enum.count(plans, &(&1.operations != [])),
        operations: counts
      }
    }

    Jason.encode_to_iodata!(payload, pretty: true)
  end

  defp plan_to_json(%Plan{} = plan) do
    %{
      module: inspect(plan.module),
      name: plan.collection_name,
      operations: Enum.map(plan.operations, &Operation.to_map/1)
    }
  end

  defp render_report_text(report, _verbose) do
    plan_results = Map.get(report, :plan_results, [])
    blocked = Map.get(report, :blocked_by_impossible, false)

    [
      if(blocked,
        do: "!! Run blocked by impossible operations — no work attempted.\n\n",
        else: []
      ),
      Enum.map(plan_results, &render_plan_result_text/1),
      render_report_summary_text(report)
    ]
  end

  defp render_plan_result_text(plan_result) do
    plan = Map.fetch!(plan_result, :plan)
    op_results = Map.get(plan_result, :op_results, [])
    load_status = Map.get(plan_result, :load_status)
    counts = result_counts(op_results)

    [
      "== ",
      inspect(plan.module),
      " → ",
      plan.collection_name,
      " ==\n",
      "  applied: ",
      Integer.to_string(counts.applied),
      ", skipped: ",
      Integer.to_string(counts.skipped_destructive + counts.skipped_idempotent),
      " (destructive=",
      Integer.to_string(counts.skipped_destructive),
      ", idempotent=",
      Integer.to_string(counts.skipped_idempotent),
      "), failed: ",
      Integer.to_string(counts.failed),
      ", blocked: ",
      Integer.to_string(counts.blocked),
      "\n",
      if(load_status,
        do: ["  load: ", format_load_status(load_status), "\n"],
        else: []
      ),
      Enum.map(op_results, fn op_result ->
        op = Map.fetch!(op_result, :operation)
        status = Map.fetch!(op_result, :status)
        ["    ", Operation.to_line(op), " (", status_to_text(status), ")\n"]
      end),
      "\n"
    ]
  end

  defp result_counts(op_results) do
    initial = %{
      applied: 0,
      skipped_destructive: 0,
      skipped_idempotent: 0,
      failed: 0,
      blocked: 0
    }

    Enum.reduce(op_results, initial, fn op_result, acc ->
      bucket = status_bucket(Map.fetch!(op_result, :status))
      Map.update!(acc, bucket, &(&1 + 1))
    end)
  end

  defp status_bucket(:ok), do: :applied
  defp status_bucket(:skipped_no_flag), do: :skipped_destructive
  defp status_bucket(:skipped_idempotent), do: :skipped_idempotent
  defp status_bucket(:blocked_by_impossible), do: :blocked
  defp status_bucket({:error, _}), do: :failed
  defp status_bucket(_), do: :failed

  defp status_to_text(:ok), do: "ok"
  defp status_to_text(:skipped_no_flag), do: "skipped: no --allow-drop"
  defp status_to_text(:skipped_idempotent), do: "skipped: idempotent"
  defp status_to_text(:blocked_by_impossible), do: "blocked by impossible"
  defp status_to_text({:error, reason}) when is_binary(reason), do: "error: " <> reason
  defp status_to_text({:error, reason}), do: "error: " <> inspect(reason)
  defp status_to_text(other), do: to_string(other)

  defp render_report_summary_text(report) do
    counts = Map.get(report, :counts, %{})
    applied = Map.get(counts, :applied, 0)
    skipped_destructive = Map.get(counts, :skipped_destructive, 0)
    skipped_idempotent = Map.get(counts, :skipped_idempotent, 0)
    failed = Map.get(counts, :failed, 0)
    blocked = Map.get(counts, :blocked, 0)
    impossible = Map.get(counts, :impossible, 0)

    [
      "== Summary ==\n",
      "  applied:              ",
      Integer.to_string(applied),
      "\n",
      "  skipped (destructive): ",
      Integer.to_string(skipped_destructive),
      "\n",
      "  skipped (idempotent):  ",
      Integer.to_string(skipped_idempotent),
      "\n",
      "  failed:               ",
      Integer.to_string(failed),
      "\n",
      "  blocked:              ",
      Integer.to_string(blocked),
      "\n",
      "  impossible:           ",
      Integer.to_string(impossible),
      "\n"
    ]
  end

  defp render_report_json(report, _verbose) do
    plan_results = Map.get(report, :plan_results, [])
    counts = Map.get(report, :counts, %{})

    payload = %{
      version: 1,
      mode: "apply",
      blocked_by_impossible: Map.get(report, :blocked_by_impossible, false),
      collections: Enum.map(plan_results, &plan_result_to_json/1),
      summary: %{
        applied: Map.get(counts, :applied, 0),
        skipped_destructive: Map.get(counts, :skipped_destructive, 0),
        skipped_idempotent: Map.get(counts, :skipped_idempotent, 0),
        failed: Map.get(counts, :failed, 0),
        blocked: Map.get(counts, :blocked, 0),
        impossible: Map.get(counts, :impossible, 0)
      }
    }

    Jason.encode_to_iodata!(payload, pretty: true)
  end

  defp plan_result_to_json(plan_result) do
    plan = Map.fetch!(plan_result, :plan)
    op_results = Map.get(plan_result, :op_results, [])
    load_status = Map.get(plan_result, :load_status)

    %{
      module: inspect(plan.module),
      name: plan.collection_name,
      load_status: load_status_to_json(load_status),
      results: Enum.map(op_results, &op_result_to_json/1)
    }
  end

  defp load_status_to_json(nil), do: nil
  defp load_status_to_json(status) when is_atom(status), do: Atom.to_string(status)

  defp load_status_to_json({tag, reason}),
    do: %{status: Atom.to_string(tag), reason: reason_text(reason)}

  defp load_status_to_json(status), do: status

  defp format_load_status({tag, reason}), do: [Atom.to_string(tag), ": ", reason_text(reason)]
  defp format_load_status(status), do: to_string(status)

  defp reason_text(reason) when is_binary(reason), do: reason
  defp reason_text(reason), do: inspect(reason)

  defp op_result_to_json(op_result) do
    op = Map.fetch!(op_result, :operation)
    status = Map.fetch!(op_result, :status)

    op
    |> Operation.to_map()
    |> Map.put(:status, status_to_json(status))
  end

  defp status_to_json(:ok), do: "ok"
  defp status_to_json(:skipped_no_flag), do: "skipped_no_flag"
  defp status_to_json(:skipped_idempotent), do: "skipped_idempotent"
  defp status_to_json(:blocked_by_impossible), do: "blocked_by_impossible"
  defp status_to_json({:error, reason}) when is_binary(reason), do: %{error: reason}
  defp status_to_json({:error, reason}), do: %{error: inspect(reason)}
  defp status_to_json(other) when is_atom(other), do: Atom.to_string(other)
  defp status_to_json(other), do: other
end
