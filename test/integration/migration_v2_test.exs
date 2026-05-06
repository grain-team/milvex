defmodule Milvex.Integration.MigrationV2Test do
  @moduledoc """
  End-to-end integration tests for `mix milvex.migrate` (Migration.CLI).

  Each test sets up an initial Milvus state, defines a target DSL module, runs
  `CLI.run/3` directly with stubbed `fetch_config_fn` and `connect_fn`, and
  asserts on the exit code plus live Milvus state via `describe_collection` /
  `describe_index`.

  DSL modules used as migration targets are defined at the top of the test
  module so Spark can process them at compile time. Prefixes are used to make
  collection names unique per test run.
  """

  use Milvex.IntegrationCase, async: false

  alias Milvex.Migration.CLI

  @moduletag :integration

  defmodule Movies do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 256)
        vector(:embedding, 4)
      end
    end

    def index_config do
      [Milvex.Index.hnsw("embedding", :cosine, m: 16, ef_construction: 256)]
    end
  end

  defmodule MoviesWithSummary do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 256)
        varchar(:summary, 1024, nullable: true)
        vector(:embedding, 4)
      end
    end

    def index_config do
      [Milvex.Index.hnsw("embedding", :cosine, m: 16, ef_construction: 256)]
    end
  end

  defmodule MoviesWiderTitle do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 1024)
        vector(:embedding, 4)
      end
    end

    def index_config do
      [Milvex.Index.hnsw("embedding", :cosine, m: 16, ef_construction: 256)]
    end
  end

  defmodule MoviesShorterTitle do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 64)
        vector(:embedding, 4)
      end
    end

    def index_config do
      [Milvex.Index.hnsw("embedding", :cosine, m: 16, ef_construction: 256)]
    end
  end

  defmodule MoviesNoLegacy do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 256)
        vector(:embedding, 4)
      end
    end

    def index_config do
      [Milvex.Index.hnsw("embedding", :cosine, m: 16, ef_construction: 256)]
    end
  end

  defmodule MoviesDifferentDim do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 256)
        vector(:embedding, 8)
      end
    end

    def index_config do
      [Milvex.Index.hnsw("embedding", :cosine, m: 16, ef_construction: 256)]
    end
  end

  defmodule MoviesIndexHigherM do
    use Milvex.Collection

    collection do
      name("movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 256)
        vector(:embedding, 4)
      end
    end

    def index_config do
      [Milvex.Index.hnsw("embedding", :cosine, m: 32, ef_construction: 512)]
    end
  end

  @movies_module "Milvex.Integration.MigrationV2Test.Movies"
  @movies_with_summary_module "Milvex.Integration.MigrationV2Test.MoviesWithSummary"
  @movies_wider_title_module "Milvex.Integration.MigrationV2Test.MoviesWiderTitle"
  @movies_shorter_title_module "Milvex.Integration.MigrationV2Test.MoviesShorterTitle"
  @movies_no_legacy_module "Milvex.Integration.MigrationV2Test.MoviesNoLegacy"
  @movies_different_dim_module "Milvex.Integration.MigrationV2Test.MoviesDifferentDim"
  @movies_index_higher_m_module "Milvex.Integration.MigrationV2Test.MoviesIndexHigherM"

  defp config(values), do: fn :milvex, :migrate -> values end
  defp connect(conn), do: fn _ -> {:ok, conn} end

  defp full_name(prefix), do: prefix <> "movies"

  defp seed_legacy_collection(conn, full, opts \\ []) do
    fields =
      Keyword.get(opts, :fields, [
        Field.primary_key("id", :int64, auto_id: true),
        Field.varchar("title", 256),
        Field.vector("embedding", 4)
      ])

    schema = Schema.build!(name: full, fields: fields)
    :ok = Milvex.create_collection(conn, full, schema)

    if Keyword.get(opts, :create_index, true) do
      idx = Index.hnsw("embedding", :cosine, m: 16, ef_construction: 256)
      :ok = Milvex.create_index(conn, full, idx)
    end

    :ok
  end

  defp index_params_map(%{params: params}) do
    Map.new(params, fn kv -> {kv.key, kv.value} end)
  end

  describe "create from nothing" do
    test "DSL + empty Milvus -> collection and index exist after --apply", %{conn: conn} do
      prefix = unique_collection_name("v2_create") <> "_"
      full = full_name(prefix)
      on_exit(fn -> cleanup_collection(conn, full) end)

      assert {:ok, false} = Milvex.has_collection(conn, full)

      {code, _io} =
        CLI.run(
          ["--apply", "--module", @movies_module, "--prefix", prefix],
          config(collections: []),
          connect(conn)
        )

      assert code == 0
      assert {:ok, true} = Milvex.has_collection(conn, full)

      {:ok, %{schema: schema}} = Milvex.describe_collection(conn, full)
      names = MapSet.new(schema.fields, & &1.name)
      assert MapSet.equal?(names, MapSet.new(["id", "title", "embedding"]))

      {:ok, [desc | _]} = Milvex.describe_index(conn, full)
      params = index_params_map(desc)
      assert params["index_type"] == "HNSW"
      assert params["metric_type"] == "COSINE"
    end
  end

  describe "additive: add nullable field" do
    @tag :skip
    test "adds varchar field with nullable: true to existing collection", %{conn: conn} do
      # Skipped: the Milvus 2.6.6 testcontainer image does not implement the
      # AlterCollectionSchema RPC that the runner uses for add_field on
      # versions >= 2.6.0. Plan-level coverage is in CLITest /
      # Migration.Runner unit tests; verify against a Milvus build that
      # actually exposes the RPC before relying on this path in production.
      prefix = unique_collection_name("v2_add") <> "_"
      full = full_name(prefix)
      on_exit(fn -> cleanup_collection(conn, full) end)

      :ok = seed_legacy_collection(conn, full)

      {code, _io} =
        CLI.run(
          ["--apply", "--module", @movies_with_summary_module, "--prefix", prefix],
          config(collections: []),
          connect(conn)
        )

      assert code == 0

      {:ok, %{schema: schema}} = Milvex.describe_collection(conn, full)
      field_names = Enum.map(schema.fields, & &1.name)
      assert "summary" in field_names

      summary = Enum.find(schema.fields, &(&1.name == "summary"))
      assert summary.data_type == :varchar
      assert summary.nullable == true
    end
  end

  describe "additive: widen varchar max_length" do
    test "widens title from 256 to 1024", %{conn: conn} do
      prefix = unique_collection_name("v2_widen") <> "_"
      full = full_name(prefix)
      on_exit(fn -> cleanup_collection(conn, full) end)

      :ok = seed_legacy_collection(conn, full)

      {code, _io} =
        CLI.run(
          ["--apply", "--module", @movies_wider_title_module, "--prefix", prefix],
          config(collections: []),
          connect(conn)
        )

      assert code == 0

      {:ok, %{schema: schema}} = Milvex.describe_collection(conn, full)
      title = Enum.find(schema.fields, &(&1.name == "title"))
      assert title.max_length == 1024
    end
  end

  describe "impossible: shrink varchar max_length" do
    test "rejects shrinking max_length with exit 2 and no mutation", %{conn: conn} do
      prefix = unique_collection_name("v2_shrink") <> "_"
      full = full_name(prefix)
      on_exit(fn -> cleanup_collection(conn, full) end)

      :ok = seed_legacy_collection(conn, full)

      {code, _io} =
        CLI.run(
          ["--apply", "--module", @movies_shorter_title_module, "--prefix", prefix],
          config(collections: []),
          connect(conn)
        )

      assert code == 2

      {:ok, %{schema: schema}} = Milvex.describe_collection(conn, full)
      title = Enum.find(schema.fields, &(&1.name == "title"))
      assert title.max_length == 256
    end
  end

  describe "destructive: drop field with --allow-drop" do
    @tag :skip
    test "drops legacy field on Milvus 2.6+", %{conn: conn} do
      # Skipped: drop_field uses the AlterCollectionSchema RPC, which the
      # Milvus 2.6.6 testcontainer image does not expose ("unknown method").
      # Plan classification, exit codes, and dispatch logic are covered by
      # the unit tests; re-enable this once the test container is on a
      # Milvus build that exposes AlterCollectionSchema.
      prefix = unique_collection_name("v2_drop") <> "_"
      full = full_name(prefix)
      on_exit(fn -> cleanup_collection(conn, full) end)

      :ok =
        seed_legacy_collection(conn, full,
          fields: [
            Field.primary_key("id", :int64, auto_id: true),
            Field.varchar("title", 256),
            Field.varchar("legacy_note", 64),
            Field.vector("embedding", 4)
          ]
        )

      {code, _io} =
        CLI.run(
          [
            "--apply",
            "--allow-drop",
            "--module",
            @movies_no_legacy_module,
            "--prefix",
            prefix
          ],
          config(collections: []),
          connect(conn)
        )

      assert code == 0

      {:ok, %{schema: schema}} = Milvex.describe_collection(conn, full)
      field_names = Enum.map(schema.fields, & &1.name)
      refute "legacy_note" in field_names
    end
  end

  describe "destructive: skip drop without --allow-drop" do
    @tag :skip
    test "exit 3 and legacy field still present, additive runs", %{conn: conn} do
      # Skipped: the additive add_field path in this test relies on
      # AlterCollectionSchema, which the Milvus 2.6.6 testcontainer image
      # does not expose. The classification/exit-code logic itself is
      # covered by Migration.CLITest.
      prefix = unique_collection_name("v2_skip_drop") <> "_"
      full = full_name(prefix)
      on_exit(fn -> cleanup_collection(conn, full) end)

      :ok =
        seed_legacy_collection(conn, full,
          fields: [
            Field.primary_key("id", :int64, auto_id: true),
            Field.varchar("title", 256),
            Field.varchar("legacy_note", 64),
            Field.vector("embedding", 4)
          ]
        )

      {code, _io} =
        CLI.run(
          ["--apply", "--module", @movies_with_summary_module, "--prefix", prefix],
          config(collections: []),
          connect(conn)
        )

      assert code == 3

      {:ok, %{schema: schema}} = Milvex.describe_collection(conn, full)
      field_names = Enum.map(schema.fields, & &1.name)
      assert "legacy_note" in field_names
      assert "summary" in field_names
    end
  end

  describe "destructive: recreate index when params differ" do
    test "drops and recreates HNSW with higher M when --allow-drop", %{conn: conn} do
      prefix = unique_collection_name("v2_idx_recreate") <> "_"
      full = full_name(prefix)
      on_exit(fn -> cleanup_collection(conn, full) end)

      :ok = seed_legacy_collection(conn, full)

      {:ok, [desc_before | _]} = Milvex.describe_index(conn, full)
      params_before = index_params_map(desc_before)
      assert params_before["M"] == "16"

      {code, _io} =
        CLI.run(
          [
            "--apply",
            "--allow-drop",
            "--module",
            @movies_index_higher_m_module,
            "--prefix",
            prefix
          ],
          config(collections: []),
          connect(conn)
        )

      assert code == 0

      {:ok, [desc_after | _]} = Milvex.describe_index(conn, full)
      params_after = index_params_map(desc_after)
      assert params_after["M"] == "32"
    end
  end

  describe "impossible: vector dimension change" do
    test "rejects with exit 2 and dimension preserved", %{conn: conn} do
      prefix = unique_collection_name("v2_dim") <> "_"
      full = full_name(prefix)
      on_exit(fn -> cleanup_collection(conn, full) end)

      :ok = seed_legacy_collection(conn, full)

      {code, _io} =
        CLI.run(
          ["--apply", "--module", @movies_different_dim_module, "--prefix", prefix],
          config(collections: []),
          connect(conn)
        )

      assert code == 2

      {:ok, %{schema: schema}} = Milvex.describe_collection(conn, full)
      embedding = Enum.find(schema.fields, &(&1.name == "embedding"))
      assert embedding.dimension == 4
    end
  end

  describe "multi-tenant: same module, multiple prefixes" do
    test "creates one collection per prefix", %{conn: conn} do
      base = unique_collection_name("v2_mt")
      prefix_a = base <> "_a_"
      prefix_b = base <> "_b_"
      full_a = full_name(prefix_a)
      full_b = full_name(prefix_b)

      on_exit(fn ->
        cleanup_collection(conn, full_a)
        cleanup_collection(conn, full_b)
      end)

      {code, _io} =
        CLI.run(
          [
            "--apply",
            "--module",
            @movies_module,
            "--prefix",
            prefix_a,
            "--prefix",
            prefix_b
          ],
          config(collections: []),
          connect(conn)
        )

      assert code == 0
      assert {:ok, true} = Milvex.has_collection(conn, full_a)
      assert {:ok, true} = Milvex.has_collection(conn, full_b)
    end
  end

  describe "continue-on-failure across plans" do
    test "impossible op in plan1 blocks all plans (exit 2)", %{conn: conn} do
      base = unique_collection_name("v2_continue")
      prefix_bad = base <> "_bad_"
      prefix_good = base <> "_good_"
      full_bad = full_name(prefix_bad)
      full_good = full_name(prefix_good)

      on_exit(fn ->
        cleanup_collection(conn, full_bad)
        cleanup_collection(conn, full_good)
      end)

      :ok = seed_legacy_collection(conn, full_bad)

      {code, _io} =
        CLI.run(
          [
            "--apply",
            "--module",
            @movies_different_dim_module,
            "--prefix",
            prefix_bad,
            "--module",
            @movies_module,
            "--prefix",
            prefix_good
          ],
          config(collections: []),
          connect(conn)
        )

      assert code == 2
      assert {:ok, false} = Milvex.has_collection(conn, full_good)
    end

    @tag :skip
    test "plan1 RPC failure does not abort plan2", %{conn: _conn} do
      # Skipped: forcing a genuine RPC failure on plan1 (without it being
      # caught earlier as :impossible) is hard to do reliably with a real
      # Milvus container; the create_collection path treats "already exists"
      # as idempotent. The Runner unit tests in `runner_test.exs` cover
      # plan-level isolation directly via stubs.
      :ok
    end
  end

  describe "manage-load releases before drop_index and reloads" do
    @tag :skip
    test "loads, releases, recreates index, then reloads", %{conn: _conn} do
      # Skipped: the load/release/reload cycle against the standalone
      # testcontainer image is timing-sensitive (load is asynchronous and
      # 2.6.6 standalone occasionally lags on transitions), which makes the
      # assertion flaky. The release/reload bookkeeping itself is covered
      # by Runner unit tests; verify against a long-running Milvus when
      # tuning this path.
      :ok
    end
  end

  describe "idempotency" do
    test "re-running --apply on the same DSL/state produces no failures", %{conn: conn} do
      prefix = unique_collection_name("v2_idem") <> "_"
      full = full_name(prefix)
      on_exit(fn -> cleanup_collection(conn, full) end)

      args = ["--apply", "--module", @movies_module, "--prefix", prefix]

      {code1, _io1} = CLI.run(args, config(collections: []), connect(conn))
      assert code1 == 0
      assert {:ok, true} = Milvex.has_collection(conn, full)

      {code2, _io2} = CLI.run(args, config(collections: []), connect(conn))
      assert code2 == 0

      {:ok, %{schema: schema}} = Milvex.describe_collection(conn, full)
      names = MapSet.new(schema.fields, & &1.name)
      assert MapSet.equal?(names, MapSet.new(["id", "title", "embedding"]))
    end
  end
end
