defmodule Milvex.Migration.RunnerTest do
  use ExUnit.Case, async: false
  use Mimic

  alias Milvex.Function
  alias Milvex.Index
  alias Milvex.Migration.Operation
  alias Milvex.Migration.Plan
  alias Milvex.Migration.Runner
  alias Milvex.Migration.Runner.ApplyReport
  alias Milvex.Migration.Runner.Context
  alias Milvex.Migration.Runner.OpResult
  alias Milvex.Migration.Runner.PlanResult
  alias Milvex.Schema
  alias Milvex.Schema.Field

  setup :verify_on_exit!

  defmodule Movies do
  end

  defmodule MoviesWithBM25 do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:content, 1024, enable_analyzer: true)
        sparse_vector(:sparse)
      end

      functions do
        bm25(:bm25_fn, input: :content, output: :sparse)
      end
    end

    def index_config, do: []
  end

  defp ctx(opts \\ []) do
    %Context{
      conn: :fake_conn,
      version: Keyword.get(opts, :version, "2.6.1"),
      allow_drop: Keyword.get(opts, :allow_drop, false),
      manage_load: Keyword.get(opts, :manage_load, false)
    }
  end

  defp plan_with(ops, name \\ "movies") do
    %Plan{
      module: Movies,
      collection_name: name,
      prefix: nil,
      operations: ops,
      milvus_version: "2.6.1"
    }
  end

  defp op(kind, category, payload, opts \\ []) do
    Operation.build(kind, category, "movies", payload, "2.6.1", opts)
  end

  defp op_for(name, kind, category, payload, opts) do
    Operation.build(kind, category, name, payload, "2.6.1", opts)
  end

  defp op_for(name, kind, category, payload), do: op_for(name, kind, category, payload, [])

  defp schema(name \\ "movies") do
    %Schema{
      name: name,
      fields: [
        %Field{name: "id", data_type: :int64, is_primary_key: true, auto_id: true},
        %Field{name: "title", data_type: :varchar, max_length: 256}
      ],
      functions: []
    }
  end

  defp field(name, data_type, attrs) do
    %Field{
      name: name,
      data_type: data_type,
      max_length: Keyword.get(attrs, :max_length),
      nullable: Keyword.get(attrs, :nullable, false),
      default_value: Keyword.get(attrs, :default_value),
      is_primary_key: Keyword.get(attrs, :is_primary_key, false),
      auto_id: Keyword.get(attrs, :auto_id, false),
      is_partition_key: Keyword.get(attrs, :is_partition_key, false),
      is_clustering_key: Keyword.get(attrs, :is_clustering_key, false),
      dimension: Keyword.get(attrs, :dimension)
    }
  end

  defp grpc_error(message) do
    %Milvex.Errors.Grpc{message: message}
  end

  describe "apply/2 - allow_drop semantics" do
    test "destructive op + allow_drop: false -> :skipped_no_flag, additive still applied" do
      add_field = field("note", :varchar, max_length: 64, nullable: true)
      drop = op(:drop_field, :destructive, %{field_name: "legacy"})
      add = op(:add_field, :additive, %{field: add_field})

      stub(Milvex, :alter_collection_schema, fn _, _, _ -> :ok end)

      report = Runner.apply([plan_with([drop, add])], ctx(allow_drop: false))

      assert %ApplyReport{
               blocked_by_impossible: false,
               counts: %{
                 applied: 1,
                 skipped_destructive: 1,
                 skipped_idempotent: 0,
                 failed: 0,
                 blocked: 0,
                 impossible: 0
               },
               plan_results: [
                 %PlanResult{
                   op_results: [
                     %OpResult{
                       operation: %Operation{kind: :drop_field},
                       status: :skipped_no_flag
                     },
                     %OpResult{operation: %Operation{kind: :add_field}, status: :ok}
                   ]
                 }
               ]
             } = report
    end

    test "destructive op + allow_drop: true -> applied" do
      drop = op(:drop_field, :destructive, %{field_name: "legacy"})

      expect(Milvex, :alter_collection_schema, fn :fake_conn, "movies", opts ->
        assert opts[:drop_fields] == ["legacy"]
        :ok
      end)

      report = Runner.apply([plan_with([drop])], ctx(allow_drop: true))

      assert %ApplyReport{
               counts: %{
                 applied: 1,
                 skipped_destructive: 0,
                 skipped_idempotent: 0,
                 failed: 0
               }
             } = report
    end
  end

  describe "apply/2 - impossible short-circuit" do
    test "any plan with impossible op -> no RPCs, blocked report" do
      reject(&Milvex.alter_collection_schema/3)
      reject(&Milvex.create_collection/4)
      reject(&Milvex.drop_index/4)

      impossible =
        op(:add_field, :impossible, %{field: field("v", :float_vector, dimension: 16)},
          reason: "vector add impossible"
        )

      add_field = field("note", :varchar, max_length: 64, nullable: true)
      additive = op(:add_field, :additive, %{field: add_field})

      report = Runner.apply([plan_with([impossible, additive])], ctx())

      assert %ApplyReport{
               blocked_by_impossible: true,
               counts: %{
                 applied: 0,
                 skipped_destructive: 0,
                 skipped_idempotent: 0,
                 failed: 0,
                 blocked: 1,
                 impossible: 1
               }
             } = report

      [%PlanResult{op_results: [r1, r2]}] = report.plan_results
      assert r1.status == :blocked_impossible
      assert r2.status == :blocked_by_impossible
    end

    test "impossible in plan2 short-circuits even plan1 additive" do
      reject(&Milvex.alter_collection_schema/3)

      additive =
        op_for("movies", :add_field, :additive, %{
          field: field("note", :varchar, max_length: 64, nullable: true)
        })

      impossible =
        op_for("shows", :drop_field, :impossible, %{field_name: "x"}, reason: "too old")

      report =
        Runner.apply([plan_with([additive], "movies"), plan_with([impossible], "shows")], ctx())

      assert %ApplyReport{
               blocked_by_impossible: true,
               counts: %{applied: 0, impossible: 1, blocked: 1}
             } = report
    end
  end

  describe "apply/2 - per-tuple isolation" do
    test "plan1 fails, plan2 still runs" do
      add_field = field("note", :varchar, max_length: 64, nullable: true)
      add1 = op_for("movies", :add_field, :additive, %{field: add_field})
      add2 = op_for("shows", :add_field, :additive, %{field: add_field})

      stub(Milvex, :alter_collection_schema, fn _, name, _ ->
        case name do
          "movies" -> {:error, grpc_error("nope")}
          "shows" -> :ok
        end
      end)

      report =
        Runner.apply(
          [plan_with([add1], "movies"), plan_with([add2], "shows")],
          ctx()
        )

      assert %ApplyReport{counts: %{applied: 1, failed: 1}} = report
    end
  end

  describe "apply/2 - manage_load" do
    test "drop_index + manage_load=true + loaded -> release/drop/load in order" do
      drop =
        op(:drop_index, :destructive, %{field_name: "embedding", index_name: "embedding_idx"})

      Milvex
      |> expect(:get_load_state, fn _, "movies", _ -> {:ok, :loaded} end)
      |> expect(:release_collection, fn _, "movies" -> :ok end)
      |> expect(:drop_index, fn _, "movies", "embedding", opts ->
        assert opts[:index_name] == "embedding_idx"
        :ok
      end)
      |> expect(:load_collection, fn _, "movies" -> :ok end)

      report = Runner.apply([plan_with([drop])], ctx(allow_drop: true, manage_load: true))

      assert %ApplyReport{counts: %{applied: 1}} = report
      [%PlanResult{load_status: :released_and_reloaded}] = report.plan_results
    end

    test "manage_load=false -> no release/load called" do
      drop =
        op(:drop_index, :destructive, %{field_name: "embedding", index_name: "embedding_idx"})

      reject(&Milvex.get_load_state/3)
      reject(&Milvex.release_collection/2)
      reject(&Milvex.load_collection/2)

      expect(Milvex, :drop_index, fn _, _, _, _ -> :ok end)

      report = Runner.apply([plan_with([drop])], ctx(allow_drop: true, manage_load: false))

      assert %ApplyReport{counts: %{applied: 1}} = report
      [%PlanResult{load_status: :unmanaged}] = report.plan_results
    end

    test "manage_load=true but op doesn't require_release -> no_release_needed" do
      add =
        op(:add_field, :additive, %{
          field: field("note", :varchar, max_length: 64, nullable: true)
        })

      reject(&Milvex.get_load_state/3)
      reject(&Milvex.release_collection/2)
      reject(&Milvex.load_collection/2)

      expect(Milvex, :alter_collection_schema, fn _, _, _ -> :ok end)

      report = Runner.apply([plan_with([add])], ctx(manage_load: true))

      [%PlanResult{load_status: :no_release_needed}] = report.plan_results
      assert report.counts.applied == 1
    end

    test "manage_load=true + not loaded -> was_not_loaded" do
      drop =
        op(:drop_index, :destructive, %{field_name: "embedding", index_name: "embedding_idx"})

      Milvex
      |> expect(:get_load_state, fn _, _, _ -> {:ok, :not_loaded} end)
      |> expect(:drop_index, fn _, _, _, _ -> :ok end)

      reject(&Milvex.release_collection/2)
      reject(&Milvex.load_collection/2)

      report = Runner.apply([plan_with([drop])], ctx(allow_drop: true, manage_load: true))

      [%PlanResult{load_status: :was_not_loaded}] = report.plan_results
      assert report.counts.applied == 1
    end

    test "release_collection failure -> plan aborted, no ops attempted" do
      drop =
        op(:drop_index, :destructive, %{field_name: "embedding", index_name: "embedding_idx"})

      Milvex
      |> expect(:get_load_state, fn _, _, _ -> {:ok, :loaded} end)
      |> expect(:release_collection, fn _, _ -> {:error, grpc_error("release failed")} end)

      reject(&Milvex.drop_index/4)
      reject(&Milvex.load_collection/2)

      report = Runner.apply([plan_with([drop])], ctx(allow_drop: true, manage_load: true))

      [%PlanResult{load_status: {:release_failed, _reason}, op_results: []}] = report.plan_results
      assert report.counts.applied == 0
    end

    test "load_collection failure after ops applied -> ops counted, reload_failed" do
      drop =
        op(:drop_index, :destructive, %{field_name: "embedding", index_name: "embedding_idx"})

      Milvex
      |> expect(:get_load_state, fn _, _, _ -> {:ok, :loaded} end)
      |> expect(:release_collection, fn _, _ -> :ok end)
      |> expect(:drop_index, fn _, _, _, _ -> :ok end)
      |> expect(:load_collection, fn _, _ -> {:error, grpc_error("reload failed")} end)

      report = Runner.apply([plan_with([drop])], ctx(allow_drop: true, manage_load: true))

      [%PlanResult{load_status: {:reload_failed, _reason}, op_results: [%OpResult{status: :ok}]}] =
        report.plan_results

      assert report.counts.applied == 1
    end
  end

  describe "apply/2 - idempotency" do
    test "create_index returning :already exists error -> :skipped_idempotent" do
      idx = Index.hnsw("embedding", :cosine, m: 16, ef_construction: 256)
      create = op(:create_index, :additive, %{index: idx})

      expect(Milvex, :create_index, fn _, _, _, _ ->
        {:error, grpc_error("index already exists")}
      end)

      report = Runner.apply([plan_with([create])], ctx())

      [%PlanResult{op_results: [%OpResult{status: :skipped_idempotent}]}] = report.plan_results
      assert report.counts.skipped_idempotent == 1
      assert report.counts.skipped_destructive == 0
    end

    test "create_collection returning already exists -> :skipped_idempotent" do
      schema = schema()
      create = op(:create_collection, :additive, %{schema: schema})

      expect(Milvex, :create_collection, fn _, _, _, _ ->
        {:error, grpc_error("collection already exists")}
      end)

      report = Runner.apply([plan_with([create])], ctx())

      [%PlanResult{op_results: [%OpResult{status: :skipped_idempotent}]}] = report.plan_results
      assert report.counts.skipped_idempotent == 1
      assert report.counts.skipped_destructive == 0
    end

    test "create_index error other than already-exists -> failed" do
      idx = Index.hnsw("embedding", :cosine, m: 16, ef_construction: 256)
      create = op(:create_index, :additive, %{index: idx})

      expect(Milvex, :create_index, fn _, _, _, _ -> {:error, grpc_error("schema mismatch")} end)

      report = Runner.apply([plan_with([create])], ctx())

      [%PlanResult{op_results: [%OpResult{status: {:error, _}}]}] = report.plan_results
      assert report.counts.failed == 1
    end

    test "create_collection unrelated 'already exists' message does not idempotent-skip" do
      schema = schema()
      create = op(:create_collection, :additive, %{schema: schema})

      expect(Milvex, :create_collection, fn _, _, _, _ ->
        {:error, grpc_error("field 'embedding' (dim 768) already exists with dim 1024")}
      end)

      report = Runner.apply([plan_with([create])], ctx())

      [%PlanResult{op_results: [%OpResult{status: {:error, _}}]}] = report.plan_results
      assert report.counts.failed == 1
      assert report.counts.skipped_idempotent == 0
      assert report.counts.skipped_destructive == 0
    end

    test "create_index unrelated 'already exists' message does not idempotent-skip" do
      idx = Index.hnsw("embedding", :cosine, m: 16, ef_construction: 256)
      create = op(:create_index, :additive, %{index: idx})

      expect(Milvex, :create_index, fn _, _, _, _ ->
        {:error, grpc_error("field 'embedding' already exists in collection")}
      end)

      report = Runner.apply([plan_with([create])], ctx())

      [%PlanResult{op_results: [%OpResult{status: {:error, _}}]}] = report.plan_results
      assert report.counts.failed == 1
      assert report.counts.skipped_idempotent == 0
      assert report.counts.skipped_destructive == 0
    end
  end

  describe "apply/2 - descriptive ops" do
    test "descriptive op -> :skipped_idempotent, no RPC" do
      desc = op(:description_change, :descriptive, %{field_name: "title", from: "old", to: "new"})

      reject(&Milvex.alter_collection_field/4)

      report = Runner.apply([plan_with([desc])], ctx())

      [%PlanResult{op_results: [%OpResult{status: :skipped_idempotent}]}] = report.plan_results
      assert report.counts.skipped_idempotent == 1
      assert report.counts.skipped_destructive == 0
    end
  end

  describe "apply/2 - kind dispatch" do
    test ":create_collection dispatch" do
      schema = schema()
      create = op(:create_collection, :additive, %{schema: schema})

      expect(Milvex, :create_collection, fn :fake_conn, "movies", ^schema, _ -> :ok end)

      report = Runner.apply([plan_with([create])], ctx())
      assert report.counts.applied == 1
    end

    test ":add_field on Milvus 2.6+ uses alter_collection_schema add_fields" do
      f = field("note", :varchar, max_length: 64, nullable: true)
      add = Operation.build(:add_field, :additive, "movies", %{field: f}, "2.6.1")

      expect(Milvex, :alter_collection_schema, fn _, "movies", opts ->
        assert opts[:add_fields] == [f]
        :ok
      end)

      report = Runner.apply([plan_with([add])], ctx(version: "2.6.1"))
      assert report.counts.applied == 1
    end

    test ":add_field on Milvus < 2.6 uses add_collection_field" do
      f = field("note", :varchar, max_length: 64, nullable: true)
      add = Operation.build(:add_field, :additive, "movies", %{field: f}, "2.5.4")

      expect(Milvex, :add_collection_field, fn _, "movies", ^f, _ -> :ok end)

      report =
        Runner.apply(
          [%Plan{plan_with([add]) | milvus_version: "2.5.4"}],
          ctx(version: "2.5.4")
        )

      assert report.counts.applied == 1
    end

    test ":drop_field uses alter_collection_schema drop_fields with single name" do
      drop = op(:drop_field, :destructive, %{field_name: "legacy"})

      expect(Milvex, :alter_collection_schema, fn _, _, opts ->
        assert opts[:drop_fields] == ["legacy"]
        :ok
      end)

      Runner.apply([plan_with([drop])], ctx(allow_drop: true))
    end

    test ":alter_field dispatch" do
      alter =
        op(:alter_field, :additive, %{
          field_name: "title",
          changes: %{max_length: [256, 512]}
        })

      expect(Milvex, :alter_collection_field, fn _, _, "title", opts ->
        assert opts[:set] == [max_length: 512]
        :ok
      end)

      Runner.apply([plan_with([alter])], ctx())
    end

    test ":create_index dispatch" do
      idx = Index.hnsw("embedding", :cosine, m: 16, ef_construction: 256)
      create = op(:create_index, :additive, %{index: idx})

      expect(Milvex, :create_index, fn _, _, ^idx, _ -> :ok end)

      Runner.apply([plan_with([create])], ctx())
    end

    test ":alter_index dispatch" do
      alter =
        op(:alter_index, :additive, %{
          index_name: "embedding_idx",
          changes: %{mmap_enabled: [false, true]}
        })

      expect(Milvex, :alter_index, fn _, _, "embedding_idx", opts ->
        assert opts[:set] == [mmap_enabled: true]
        :ok
      end)

      Runner.apply([plan_with([alter])], ctx())
    end

    test ":recreate_index does drop + create using dsl_index" do
      idx = Index.hnsw("embedding", :cosine, m: 32, ef_construction: 256)

      recreate =
        op(:recreate_index, :destructive, %{
          field_name: "embedding",
          old: %{index_type: "HNSW"},
          new: %{index_type: "HNSW"},
          dsl_index: idx
        })

      Milvex
      |> expect(:get_load_state, fn _, _, _ -> {:ok, :not_loaded} end)
      |> expect(:drop_index, fn _, _, "embedding", _ -> :ok end)
      |> expect(:create_index, fn _, _, ^idx, _ -> :ok end)

      report =
        Runner.apply(
          [plan_with([recreate])],
          ctx(allow_drop: true, manage_load: true)
        )

      assert report.counts.applied == 1
    end

    test ":add_function dispatch" do
      fun = Function.new("bm25_fn", :BM25)
      add = op(:add_function, :additive, %{function: fun})

      expect(Milvex, :add_collection_function, fn _, _, ^fun, _ -> :ok end)

      Runner.apply([plan_with([add])], ctx())
    end

    test ":alter_function dispatch" do
      fun = Function.new("bm25_fn", :BM25)

      alter =
        op(:alter_function, :additive, %{
          function_name: "bm25_fn",
          changes: %{params: [%{}, %{"k1" => "1.5"}]},
          dsl_function: fun
        })

      expect(Milvex, :alter_collection_function, fn _, _, ^fun, _ -> :ok end)

      Runner.apply([plan_with([alter])], ctx())
    end

    test ":drop_function dispatch" do
      drop = op(:drop_function, :destructive, %{function_name: "bm25_fn"})

      expect(Milvex, :drop_collection_function, fn _, _, "bm25_fn", _ -> :ok end)

      Runner.apply([plan_with([drop])], ctx(allow_drop: true))
    end

    test ":alter_collection dispatch with set/delete" do
      alter =
        op(:alter_collection, :additive, %{
          set: [ttl_seconds: 3600],
          delete: [:foo]
        })

      expect(Milvex, :alter_collection, fn _, _, opts ->
        assert opts[:set] == [ttl_seconds: 3600]
        assert opts[:delete] == [:foo]
        :ok
      end)

      Runner.apply([plan_with([alter])], ctx())
    end
  end

  describe "apply/2 - end-to-end Plan->Runner" do
    test "Plan.diff produces alter_function that Runner dispatches with %Function{}" do
      live_fn =
        Function.new("bm25_fn", :BM25)
        |> Function.input_field_names(["old_content"])
        |> Function.output_field_names(["old_sparse"])
        |> Function.param("k1", "1.5")

      live_schema = %Schema{
        name: "movies",
        fields: [
          %Field{name: "id", data_type: :int64, is_primary_key: true, auto_id: true},
          %Field{name: "content", data_type: :varchar, max_length: 1024},
          %Field{name: "sparse", data_type: :sparse_float_vector}
        ],
        functions: [live_fn]
      }

      plan = Plan.diff(MoviesWithBM25, nil, %{schema: live_schema, indexes: []}, "2.6.1")

      assert Enum.any?(plan.operations, fn op ->
               op.kind == :alter_function and match?(%Function{}, op.payload[:dsl_function])
             end)

      expect(Milvex, :alter_collection_function, fn :fake_conn,
                                                    "movies",
                                                    %Function{name: "bm25_fn"} = passed,
                                                    _opts ->
        assert passed.input_field_names == ["content"]
        assert passed.output_field_names == ["sparse"]
        :ok
      end)

      report = Runner.apply([plan], ctx())

      assert report.counts.applied >= 1
      refute report.blocked_by_impossible
    end
  end

  describe "apply/2 - telemetry" do
    test "emits run start/stop and op start/stop with expected metadata" do
      handler = self()

      events = [
        [:milvex, :migrate, :run, :start],
        [:milvex, :migrate, :run, :stop],
        [:milvex, :migrate, :op, :start],
        [:milvex, :migrate, :op, :stop]
      ]

      :telemetry.attach_many(
        "test-runner-#{System.unique_integer()}",
        events,
        fn event, measurements, metadata, _ ->
          send(handler, {:telemetry, event, measurements, metadata})
        end,
        nil
      )

      idx = Index.hnsw("embedding", :cosine, m: 16, ef_construction: 256)
      create = op(:create_index, :additive, %{index: idx})

      stub(Milvex, :create_index, fn _, _, _, _ -> :ok end)

      Runner.apply([plan_with([create])], ctx(allow_drop: true, manage_load: true))

      assert_receive {:telemetry, [:milvex, :migrate, :run, :start], _,
                      %{mode: :apply, allow_drop: true, manage_load: true}}

      assert_receive {:telemetry, [:milvex, :migrate, :op, :start], _,
                      %{
                        kind: :create_index,
                        category: :additive,
                        collection_name: "movies",
                        module: Movies,
                        milvus_version: "2.6.1"
                      }}

      assert_receive {:telemetry, [:milvex, :migrate, :op, :stop], _, %{result: :ok}}

      assert_receive {:telemetry, [:milvex, :migrate, :run, :stop], _, %{summary: %{applied: 1}}}

      :telemetry.detach("test-runner-#{System.unique_integer()}")
    end
  end
end
