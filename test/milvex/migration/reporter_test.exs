defmodule Milvex.Migration.ReporterTest do
  use ExUnit.Case, async: true

  alias Milvex.Migration.Operation
  alias Milvex.Migration.Plan
  alias Milvex.Migration.Reporter
  alias Milvex.Schema.Field

  defmodule Fake do
    defmodule ApplyReport do
      defstruct [:plan_results, :blocked_by_impossible, :counts]
    end

    defmodule PlanResult do
      defstruct [:plan, :op_results, :load_status]
    end

    defmodule OpResult do
      defstruct [:operation, :status]
    end
  end

  defmodule Movies do
  end

  describe "text rendering — plans" do
    test "shows additive count and + prefix" do
      plan =
        build_plan([
          Operation.build(
            :add_field,
            :additive,
            "movies",
            %{field: Field.varchar("description", 1024, nullable: true)},
            "2.6.1"
          )
        ])

      out = IO.iodata_to_binary(Reporter.render([plan], format: :text))
      assert out =~ "Additive (1)"
      assert out =~ "+ add field"
      assert out =~ "description"
    end

    test "shows destructive group with --allow-drop notice and - prefix" do
      plan =
        build_plan([
          Operation.build(
            :drop_field,
            :destructive,
            "movies",
            %{field_name: "legacy_score"},
            "2.6.1"
          )
        ])

      out = IO.iodata_to_binary(Reporter.render([plan], format: :text))
      assert out =~ "Destructive (1) — gated by --allow-drop:"
      assert out =~ "- drop field"
      assert out =~ "legacy_score"
    end

    test "shows impossible ops with reason: line" do
      plan =
        build_plan([
          Operation.build(
            :alter_field,
            :impossible,
            "movies",
            %{field_name: "embedding", changes: %{}},
            "2.6.1",
            reason: "vector dimension cannot be altered"
          )
        ])

      out = IO.iodata_to_binary(Reporter.render([plan], format: :text))
      assert out =~ "Impossible (1)"
      assert out =~ "reason: vector dimension cannot be altered"
    end

    test "shows descriptive-only group with cannot-be-applied notice" do
      plan =
        build_plan([
          Operation.build(
            :description_change,
            :descriptive,
            "movies",
            %{field_name: "title", from: "old", to: "new"},
            "2.6.1"
          )
        ])

      out = IO.iodata_to_binary(Reporter.render([plan], format: :text))
      assert out =~ "Descriptive-only (1) (cannot be applied):"
      assert out =~ "~"
    end

    test "summary block totals counts across all plans" do
      plan_a =
        build_plan([
          Operation.build(
            :add_field,
            :additive,
            "movies",
            %{field: Field.varchar("a", 100, nullable: true)},
            "2.6.1"
          ),
          Operation.build(
            :add_field,
            :additive,
            "movies",
            %{field: Field.varchar("b", 100, nullable: true)},
            "2.6.1"
          ),
          Operation.build(
            :drop_field,
            :destructive,
            "movies",
            %{field_name: "x"},
            "2.6.1"
          )
        ])

      plan_b =
        build_plan(
          [
            Operation.build(
              :add_field,
              :additive,
              "shows",
              %{field: Field.varchar("c", 100, nullable: true)},
              "2.6.1"
            ),
            Operation.build(
              :description_change,
              :descriptive,
              "shows",
              %{field_name: "title", from: "x", to: "y"},
              "2.6.1"
            ),
            Operation.build(
              :alter_field,
              :impossible,
              "shows",
              %{field_name: "v", changes: %{}},
              "2.6.1",
              reason: "no"
            ),
            Operation.build(
              :alter_field,
              :impossible,
              "shows",
              %{field_name: "w", changes: %{}},
              "2.6.1",
              reason: "no"
            )
          ],
          collection_name: "shows"
        )

      out = IO.iodata_to_binary(Reporter.render([plan_a, plan_b], format: :text))

      assert out =~ "== Summary =="
      assert out =~ "collections inspected:    2"
      assert out =~ "collections with changes: 2"
      assert out =~ "additive=3"
      assert out =~ "destructive=1"
      assert out =~ "descriptive=1"
      assert out =~ "impossible=2"
    end
  end

  describe "json rendering — plans" do
    test "decodes to expected shape with version, mode, collections, and summary" do
      plan =
        build_plan([
          Operation.build(
            :add_field,
            :additive,
            "movies",
            %{field: Field.varchar("description", 1024, nullable: true)},
            "2.6.1"
          )
        ])

      out = IO.iodata_to_binary(Reporter.render([plan], format: :json))
      decoded = Jason.decode!(out)

      assert decoded["version"] == 1
      assert decoded["mode"] == "plan"

      assert [%{"name" => "movies", "module" => module, "operations" => [op]}] =
               decoded["collections"]

      assert is_binary(module)
      assert op["kind"] == "add_field"
      assert op["category"] == "additive"
      assert op["field"]["name"] == "description"

      assert decoded["summary"]["collections_inspected"] == 1
      assert decoded["summary"]["collections_with_changes"] == 1
      assert decoded["summary"]["operations"]["additive"] == 1
      assert decoded["summary"]["operations"]["destructive"] == 0
      assert decoded["summary"]["operations"]["descriptive"] == 0
      assert decoded["summary"]["operations"]["impossible"] == 0
    end
  end

  describe "text rendering — apply report" do
    test "shows blocked notice when blocked_by_impossible is true" do
      report = %Fake.ApplyReport{
        plan_results: [],
        blocked_by_impossible: true,
        counts: %{
          applied: 0,
          skipped_destructive: 0,
          skipped_idempotent: 0,
          failed: 0,
          blocked: 0,
          impossible: 1
        }
      }

      out = IO.iodata_to_binary(Reporter.render(report, format: :text))
      assert out =~ "!! Run blocked by impossible operations — no work attempted."
    end

    test "shows per-collection breakdown with applied/skipped/failed counts" do
      plan =
        build_plan([
          Operation.build(
            :add_field,
            :additive,
            "movies",
            %{field: Field.varchar("description", 1024, nullable: true)},
            "2.6.1"
          ),
          Operation.build(
            :drop_field,
            :destructive,
            "movies",
            %{field_name: "legacy"},
            "2.6.1"
          )
        ])

      [add_op, drop_op] = plan.operations

      plan_result = %Fake.PlanResult{
        plan: plan,
        load_status: :released_and_reloaded,
        op_results: [
          %Fake.OpResult{operation: add_op, status: :ok},
          %Fake.OpResult{operation: drop_op, status: :skipped_no_flag}
        ]
      }

      report = %Fake.ApplyReport{
        plan_results: [plan_result],
        blocked_by_impossible: false,
        counts: %{
          applied: 1,
          skipped_destructive: 1,
          skipped_idempotent: 0,
          failed: 0,
          blocked: 0,
          impossible: 0
        }
      }

      out = IO.iodata_to_binary(Reporter.render(report, format: :text))

      assert out =~ "applied: 1"
      assert out =~ "skipped: 1 (destructive=1, idempotent=0)"
      assert out =~ "failed: 0"
      assert out =~ "blocked: 0"
      assert out =~ "load: released_and_reloaded"
      assert out =~ "+ add field"
      assert out =~ "(ok)"
      assert out =~ "- drop field"
      assert out =~ "(skipped: no --allow-drop)"
      assert out =~ "skipped (destructive): 1"
      assert out =~ "skipped (idempotent):  0"
    end
  end

  describe "json rendering — apply report" do
    test "decodes to expected apply-report shape" do
      plan =
        build_plan([
          Operation.build(
            :add_field,
            :additive,
            "movies",
            %{field: Field.varchar("description", 1024, nullable: true)},
            "2.6.1"
          )
        ])

      [add_op] = plan.operations

      plan_result = %Fake.PlanResult{
        plan: plan,
        load_status: :released_and_reloaded,
        op_results: [
          %Fake.OpResult{operation: add_op, status: :ok}
        ]
      }

      report = %Fake.ApplyReport{
        plan_results: [plan_result],
        blocked_by_impossible: false,
        counts: %{
          applied: 1,
          skipped_destructive: 0,
          skipped_idempotent: 0,
          failed: 0,
          blocked: 0,
          impossible: 0
        }
      }

      out = IO.iodata_to_binary(Reporter.render(report, format: :json))
      decoded = Jason.decode!(out)

      assert decoded["version"] == 1
      assert decoded["mode"] == "apply"
      assert decoded["blocked_by_impossible"] == false

      assert [
               %{
                 "module" => _module,
                 "name" => "movies",
                 "load_status" => "released_and_reloaded",
                 "results" => [result]
               }
             ] = decoded["collections"]

      assert result["kind"] == "add_field"
      assert result["category"] == "additive"
      assert result["status"] == "ok"
      assert result["field"]["name"] == "description"

      assert decoded["summary"]["applied"] == 1
      assert decoded["summary"]["skipped_destructive"] == 0
      assert decoded["summary"]["skipped_idempotent"] == 0
      assert decoded["summary"]["failed"] == 0
      assert decoded["summary"]["blocked"] == 0
      assert decoded["summary"]["impossible"] == 0
    end

    test "serializes failure status as {error: reason}" do
      plan =
        build_plan([
          Operation.build(
            :add_field,
            :additive,
            "movies",
            %{field: Field.varchar("description", 1024, nullable: true)},
            "2.6.1"
          )
        ])

      [add_op] = plan.operations

      plan_result = %Fake.PlanResult{
        plan: plan,
        load_status: :no_change,
        op_results: [
          %Fake.OpResult{operation: add_op, status: {:error, "boom"}}
        ]
      }

      report = %Fake.ApplyReport{
        plan_results: [plan_result],
        blocked_by_impossible: false,
        counts: %{
          applied: 0,
          skipped_destructive: 0,
          skipped_idempotent: 0,
          failed: 1,
          blocked: 0,
          impossible: 0
        }
      }

      out = IO.iodata_to_binary(Reporter.render(report, format: :json))
      decoded = Jason.decode!(out)

      [%{"results" => [result]}] = decoded["collections"]
      assert result["status"] == %{"error" => "boom"}
    end
  end

  defp build_plan(ops, opts \\ []) do
    %Plan{
      module: Keyword.get(opts, :module, Movies),
      collection_name: Keyword.get(opts, :collection_name, "movies"),
      prefix: nil,
      operations: ops,
      milvus_version: "2.6.1"
    }
  end
end
