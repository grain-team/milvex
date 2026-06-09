defmodule Milvex.Migration.CLITest do
  use ExUnit.Case, async: true
  use Mimic

  alias Milvex.Index
  alias Milvex.Migration.CLI
  alias Milvex.Schema
  alias Milvex.Schema.Field

  setup :verify_on_exit!

  defmodule FakeCol do
    use Milvex.Collection

    collection do
      name("fake_movies")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 256)
        vector(:embedding, 4)
      end
    end

    def index_config do
      [Index.hnsw("embedding", :cosine, m: 16, ef_construction: 256)]
    end
  end

  defmodule FakeColWithDesc do
    use Milvex.Collection

    collection do
      name("fake_movies_desc")

      fields do
        primary_key(:id, :int64, auto_id: true)
        varchar(:title, 256, description: "movie title")
      end
    end

    def index_config, do: []
  end

  defp config(values) do
    fn :milvex, :migrate -> values end
  end

  defp connect(_), do: {:ok, :fake_conn}

  defp stub_version do
    stub(Milvex, :get_version, fn _, _ -> {:ok, "2.6.1"} end)
  end

  defp stub_no_collection do
    stub(Milvex, :has_collection, fn _, _, _ -> {:ok, false} end)
  end

  defp stub_live_collection_with_extra_field do
    live_schema = %Schema{
      name: "fake_movies",
      fields: [
        %Field{name: "id", data_type: :int64, is_primary_key: true, auto_id: true},
        %Field{name: "title", data_type: :varchar, max_length: 256},
        %Field{name: "embedding", data_type: :float_vector, dimension: 4},
        %Field{name: "extra_legacy", data_type: :varchar, max_length: 64}
      ],
      functions: []
    }

    stub(Milvex, :has_collection, fn _, _, _ -> {:ok, true} end)
    stub(Milvex, :describe_collection, fn _, _, _ -> {:ok, %{schema: live_schema}} end)
    stub(Milvex, :describe_index, fn _, _, _ -> {:ok, []} end)
  end

  defp stub_live_collection_with_dim_mismatch do
    live_schema = %Schema{
      name: "fake_movies",
      fields: [
        %Field{name: "id", data_type: :int64, is_primary_key: true, auto_id: true},
        %Field{name: "title", data_type: :varchar, max_length: 256},
        %Field{name: "embedding", data_type: :float_vector, dimension: 8}
      ],
      functions: []
    }

    stub(Milvex, :has_collection, fn _, _, _ -> {:ok, true} end)
    stub(Milvex, :describe_collection, fn _, _, _ -> {:ok, %{schema: live_schema}} end)
    stub(Milvex, :describe_index, fn _, _, _ -> {:ok, []} end)
  end

  defp stub_live_collection_clean do
    live_schema = %Schema{
      name: "fake_movies",
      fields: [
        %Field{name: "id", data_type: :int64, is_primary_key: true, auto_id: true},
        %Field{name: "title", data_type: :varchar, max_length: 256},
        %Field{name: "embedding", data_type: :float_vector, dimension: 4}
      ],
      functions: []
    }

    stub(Milvex, :has_collection, fn _, _, _ -> {:ok, true} end)
    stub(Milvex, :describe_collection, fn _, _, _ -> {:ok, %{schema: live_schema}} end)

    live_indexes = [
      %Milvex.Milvus.Proto.Milvus.IndexDescription{
        field_name: "embedding",
        index_name: "embedding_idx",
        params: [
          %Milvex.Milvus.Proto.Common.KeyValuePair{key: "index_type", value: "HNSW"},
          %Milvex.Milvus.Proto.Common.KeyValuePair{key: "metric_type", value: "COSINE"},
          %Milvex.Milvus.Proto.Common.KeyValuePair{key: "M", value: "16"},
          %Milvex.Milvus.Proto.Common.KeyValuePair{key: "efConstruction", value: "256"}
        ]
      }
    ]

    stub(Milvex, :describe_index, fn _, _, _ -> {:ok, live_indexes} end)
  end

  defp stub_live_collection_index_drift do
    live_schema = %Schema{
      name: "fake_movies",
      fields: [
        %Field{name: "id", data_type: :int64, is_primary_key: true, auto_id: true},
        %Field{name: "title", data_type: :varchar, max_length: 256},
        %Field{name: "embedding", data_type: :float_vector, dimension: 4}
      ],
      functions: []
    }

    stub(Milvex, :has_collection, fn _, _, _ -> {:ok, true} end)
    stub(Milvex, :describe_collection, fn _, _, _ -> {:ok, %{schema: live_schema}} end)

    live_indexes = [
      %Milvex.Milvus.Proto.Milvus.IndexDescription{
        field_name: "embedding",
        index_name: "embedding_idx",
        params: [
          %Milvex.Milvus.Proto.Common.KeyValuePair{key: "index_type", value: "HNSW"},
          %Milvex.Milvus.Proto.Common.KeyValuePair{key: "metric_type", value: "COSINE"},
          %Milvex.Milvus.Proto.Common.KeyValuePair{key: "M", value: "8"},
          %Milvex.Milvus.Proto.Common.KeyValuePair{key: "efConstruction", value: "256"}
        ]
      }
    ]

    stub(Milvex, :describe_index, fn _, _, _ -> {:ok, live_indexes} end)
  end

  describe "argv parsing" do
    test "no mode -> exit 1 with 'specify --plan or --apply'" do
      cfg = config(collections: [FakeCol])

      {code, io} = CLI.run([], cfg, &connect/1)

      assert code == 1
      output = IO.iodata_to_binary(io)
      assert output =~ "specify --plan or --apply"
      assert output =~ "Usage: mix milvex.migrate"
    end

    test "both --plan and --apply -> exit 1 'mutually exclusive'" do
      cfg = config(collections: [FakeCol])

      {code, io} = CLI.run(["--plan", "--apply"], cfg, &connect/1)

      assert code == 1
      assert IO.iodata_to_binary(io) =~ "mutually exclusive"
    end

    test "unknown --format value -> exit 1" do
      cfg = config(collections: [FakeCol])

      {code, io} = CLI.run(["--plan", "--format", "yaml"], cfg, &connect/1)

      assert code == 1
      assert IO.iodata_to_binary(io) =~ "unknown --format"
    end
  end

  describe "configuration discovery" do
    test "no :collections AND no --module -> exit 1 'no collections configured'" do
      cfg = config([])

      {code, io} = CLI.run(["--plan"], cfg, &connect/1)

      assert code == 1
      assert IO.iodata_to_binary(io) =~ "no collections configured"
    end

    test "--module overrides config" do
      cfg = config(collections: [Some.OtherModule])
      stub_version()
      stub_no_collection()

      {code, _io} =
        CLI.run(
          [
            "--plan",
            "--module",
            "Milvex.Migration.CLITest.FakeCol"
          ],
          cfg,
          &connect/1
        )

      assert code == 0
    end

    test "unknown --module -> exit 1" do
      cfg = config([])

      {code, io} = CLI.run(["--plan", "--module", "Not.Real.Module"], cfg, &connect/1)

      assert code == 1
      assert IO.iodata_to_binary(io) =~ "unknown module"
    end

    test "unknown --module does not intern a new atom" do
      cfg = config([])
      name = "Definitely.Not.A.Real.Module.Xyzzy42"

      {code, _io} = CLI.run(["--plan", "--module", name], cfg, &connect/1)

      assert code == 1

      assert_raise ArgumentError, fn ->
        String.to_existing_atom("Elixir." <> name)
      end
    end
  end

  describe "connection" do
    test "no connection configured -> exit 1" do
      cfg = config(collections: [FakeCol])

      connect_fn = fn nil -> {:error, :no_connection} end

      {code, io} = CLI.run(["--plan"], cfg, connect_fn)

      assert code == 1
      assert IO.iodata_to_binary(io) =~ "no :connection configured"
    end

    test "connect failure -> exit 1" do
      cfg = config(collections: [FakeCol], connection: :fake_conn)

      connect_fn = fn :fake_conn -> {:error, :connect_failed, "process not alive"} end

      {code, io} = CLI.run(["--plan"], cfg, connect_fn)

      assert code == 1
      assert IO.iodata_to_binary(io) =~ "could not acquire connection"
    end

    test "unknown --connection -> exit 1 without interning a new atom" do
      cfg = config(collections: [FakeCol])
      name = "no_such_conn_xyzzy_42"

      {code, io} = CLI.run(["--plan", "--connection", name], cfg, &connect/1)

      assert code == 1
      assert IO.iodata_to_binary(io) =~ "unknown connection"

      assert_raise ArgumentError, fn -> String.to_existing_atom(name) end
    end
  end

  describe "prefix resolver" do
    test "MFA resolver returning a list is used" do
      cfg = config(collections: [FakeCol], prefix_resolver: {List, :wrap, [["tenant_"]]})
      stub_version()
      stub_no_collection()

      {code, _io} = CLI.run(["--plan"], cfg, &connect/1)

      assert code == 0
    end

    test "non-MFA resolver -> exit 1" do
      cfg = config(collections: [FakeCol], prefix_resolver: :not_a_tuple)

      {code, io} = CLI.run(["--plan"], cfg, &connect/1)

      assert code == 1
      assert IO.iodata_to_binary(io) =~ "prefix_resolver"
    end

    test "resolver function not exported -> exit 1" do
      cfg = config(collections: [FakeCol], prefix_resolver: {Milvex.Migration.CLI, :nope, []})

      {code, io} = CLI.run(["--plan"], cfg, &connect/1)

      assert code == 1
      assert IO.iodata_to_binary(io) =~ "prefix_resolver"
    end

    test "resolver returning a non-list -> exit 1" do
      cfg = config(collections: [FakeCol], prefix_resolver: {Atom, :to_string, [:foo]})

      {code, io} = CLI.run(["--plan"], cfg, &connect/1)

      assert code == 1
      assert IO.iodata_to_binary(io) =~ "prefix_resolver"
    end

    test "resolver that raises -> exit 1" do
      cfg = config(collections: [FakeCol], prefix_resolver: {Kernel, :hd, [[]]})

      {code, io} = CLI.run(["--plan"], cfg, &connect/1)

      assert code == 1
      assert IO.iodata_to_binary(io) =~ "prefix_resolver"
    end
  end

  describe "version fetch" do
    test "get_version failure -> exit 1" do
      cfg = config(collections: [FakeCol])
      stub(Milvex, :get_version, fn _, _ -> {:error, %Milvex.Errors.Grpc{message: "boom"}} end)

      {code, io} = CLI.run(["--plan"], cfg, &connect/1)

      assert code == 1
      assert IO.iodata_to_binary(io) =~ "could not fetch Milvus version"
    end
  end

  describe "exit code priority - plan mode" do
    test "impossible op -> exit 2" do
      cfg = config(collections: [FakeCol])
      stub_version()
      stub_live_collection_with_dim_mismatch()

      {code, _io} = CLI.run(["--plan"], cfg, &connect/1)

      assert code == 2
    end

    test "destructive without --allow-drop -> exit 3" do
      cfg = config(collections: [FakeCol])
      stub_version()
      stub_live_collection_with_extra_field()

      {code, _io} = CLI.run(["--plan"], cfg, &connect/1)

      assert code == 3
    end

    test "destructive WITH --allow-drop -> exit 0" do
      cfg = config(collections: [FakeCol])
      stub_version()
      stub_live_collection_with_extra_field()

      {code, _io} = CLI.run(["--plan", "--allow-drop"], cfg, &connect/1)

      assert code == 0
    end

    test "clean (live matches) -> exit 0" do
      cfg = config(collections: [FakeCol])
      stub_version()
      stub_live_collection_clean()

      {code, _io} = CLI.run(["--plan"], cfg, &connect/1)

      assert code == 0
    end

    test "describe_collection error -> exit 4" do
      cfg = config(collections: [FakeCol])
      stub_version()
      stub(Milvex, :has_collection, fn _, _, _ -> {:ok, true} end)

      stub(Milvex, :describe_collection, fn _, _, _ ->
        {:error, %Milvex.Errors.Grpc{message: "boom"}}
      end)

      {code, io} = CLI.run(["--plan"], cfg, &connect/1)

      assert code == 4
      assert IO.iodata_to_binary(io) =~ "describe failed"
    end
  end

  describe "exit code priority - apply mode" do
    test "impossible -> exit 2 (no apply RPCs)" do
      cfg = config(collections: [FakeCol])
      stub_version()
      stub_live_collection_with_dim_mismatch()

      reject(&Milvex.create_collection/4)
      reject(&Milvex.alter_collection_schema/3)

      {code, _io} = CLI.run(["--apply"], cfg, &connect/1)

      assert code == 2
    end

    test "destructive without --allow-drop -> exit 3 (additive proceeds)" do
      cfg = config(collections: [FakeCol])
      stub_version()
      stub_live_collection_with_extra_field()

      stub(Milvex, :alter_collection_schema, fn _, _, _ -> :ok end)
      stub(Milvex, :create_index, fn _, _, _, _ -> :ok end)

      {code, _io} = CLI.run(["--apply"], cfg, &connect/1)

      assert code == 3
    end

    test "RPC failure -> exit 4" do
      cfg = config(collections: [FakeCol])
      stub_version()
      stub_no_collection()

      stub(Milvex, :create_collection, fn _, _, _, _ ->
        {:error, %Milvex.Errors.Grpc{message: "create failed"}}
      end)

      stub(Milvex, :create_index, fn _, _, _, _ -> :ok end)

      {code, _io} = CLI.run(["--apply"], cfg, &connect/1)

      assert code == 4
    end

    test "clean apply -> exit 0" do
      cfg = config(collections: [FakeCol])
      stub_version()
      stub_no_collection()

      stub(Milvex, :create_collection, fn _, _, _, _ -> :ok end)
      stub(Milvex, :create_index, fn _, _, _, _ -> :ok end)

      {code, _io} = CLI.run(["--apply"], cfg, &connect/1)

      assert code == 0
    end

    test "release failure under --manage-load -> exit 4" do
      cfg = config(collections: [FakeCol])
      stub_version()
      stub_live_collection_index_drift()

      stub(Milvex, :get_load_state, fn _, _, _ -> {:ok, :loaded} end)

      stub(Milvex, :release_collection, fn _, _ ->
        {:error, %Milvex.Errors.Grpc{message: "release failed"}}
      end)

      {code, _io} = CLI.run(["--apply", "--allow-drop", "--manage-load"], cfg, &connect/1)

      assert code == 4
    end

    test "descriptive-only ops (no destructive) -> exit 0 (regression: was 3)" do
      cfg = config(collections: [FakeColWithDesc])
      stub_version()

      live_schema = %Schema{
        name: "fake_movies_desc",
        fields: [
          %Field{name: "id", data_type: :int64, is_primary_key: true, auto_id: true},
          %Field{
            name: "title",
            data_type: :varchar,
            max_length: 256,
            description: "stale description"
          }
        ],
        functions: []
      }

      stub(Milvex, :has_collection, fn _, _, _ -> {:ok, true} end)
      stub(Milvex, :describe_collection, fn _, _, _ -> {:ok, %{schema: live_schema}} end)
      stub(Milvex, :describe_index, fn _, _, _ -> {:ok, []} end)

      reject(&Milvex.alter_collection_schema/3)
      reject(&Milvex.alter_collection_field/4)

      {code, _io} = CLI.run(["--apply"], cfg, &connect/1)

      assert code == 0
    end

    test "create_index already-exists idempotent skip -> exit 0" do
      cfg = config(collections: [FakeCol])
      stub_version()
      stub_no_collection()

      stub(Milvex, :create_collection, fn _, _, _, _ -> :ok end)

      stub(Milvex, :create_index, fn _, _, _, _ ->
        {:error, %Milvex.Errors.Grpc{message: "index already exists"}}
      end)

      {code, _io} = CLI.run(["--apply"], cfg, &connect/1)

      assert code == 0
    end

    test "destructive drop_field without --allow-drop -> exit 3 (counts.skipped_destructive > 0)" do
      cfg = config(collections: [FakeCol])
      stub_version()
      stub_live_collection_with_extra_field()

      stub(Milvex, :alter_collection_schema, fn _, _, _ -> :ok end)
      stub(Milvex, :create_index, fn _, _, _, _ -> :ok end)

      {code, _io} = CLI.run(["--apply"], cfg, &connect/1)

      assert code == 3
    end
  end

  describe "format=json" do
    test "produces parseable JSON" do
      cfg = config(collections: [FakeCol])
      stub_version()
      stub_no_collection()

      {code, io} = CLI.run(["--plan", "--format", "json"], cfg, &connect/1)

      assert code == 0
      decoded = io |> IO.iodata_to_binary() |> Jason.decode!()
      assert decoded["mode"] == "plan"
      assert is_list(decoded["collections"])
    end
  end

  describe "prefix resolution" do
    test "--prefix flags applied across modules" do
      cfg = config(collections: [FakeCol])
      stub_version()
      stub(Milvex, :has_collection, fn _, name, _ -> {:ok, name == "tenant_a_fake_movies"} end)

      stub(Milvex, :describe_collection, fn _, _, _ ->
        live_schema = %Schema{
          name: "tenant_a_fake_movies",
          fields: [
            %Field{name: "id", data_type: :int64, is_primary_key: true, auto_id: true},
            %Field{name: "title", data_type: :varchar, max_length: 256},
            %Field{name: "embedding", data_type: :float_vector, dimension: 4}
          ],
          functions: []
        }

        {:ok, %{schema: live_schema}}
      end)

      stub(Milvex, :describe_index, fn _, _, _ -> {:ok, []} end)

      {code, io} =
        CLI.run(
          ["--plan", "--prefix", "tenant_a_", "--prefix", "tenant_b_", "--format", "json"],
          cfg,
          &connect/1
        )

      assert code == 0
      decoded = io |> IO.iodata_to_binary() |> Jason.decode!()
      names = Enum.map(decoded["collections"], & &1["name"])
      assert "tenant_a_fake_movies" in names
      assert "tenant_b_fake_movies" in names
    end
  end
end
