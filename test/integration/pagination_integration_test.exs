defmodule Milvex.Integration.PaginationTest do
  use Milvex.IntegrationCase, async: false

  @moduletag :integration
  @moduletag timeout: 180_000

  defp setup_vector_collection(conn, name, opts) do
    dim = Keyword.get(opts, :dim, 4)
    total = Keyword.fetch!(opts, :total)

    schema =
      Schema.build!(
        name: name,
        fields: [
          Field.primary_key("id", :int64, auto_id: false),
          Field.vector("embedding", dim)
        ]
      )

    :ok = Milvex.create_collection(conn, name, schema)

    :ok =
      Milvex.create_index(conn, name, "embedding",
        index_type: "AUTOINDEX",
        metric_type: "COSINE"
      )

    rows =
      Enum.map(0..(total - 1), fn i ->
        %{id: i, embedding: random_vector(dim)}
      end)

    rows
    |> Enum.chunk_every(2_000)
    |> Enum.each(fn chunk ->
      data = Data.from_rows!(chunk, schema)
      {:ok, _} = Milvex.insert(conn, name, data)
    end)

    :ok = Milvex.load_collection(conn, name)

    schema
  end

  describe "search_stream/4 (integration)" do
    test "streams a collection larger than the 16384 cap", %{conn: conn} do
      name = unique_collection_name("stream_large")
      on_exit(fn -> cleanup_collection(conn, name) end)

      setup_vector_collection(conn, name, dim: 4, total: 20_000)

      hits =
        Milvex.search_stream(conn, name, [0.1, 0.2, 0.3, 0.4],
          vector_field: "embedding",
          batch_size: 2_000,
          filter: "id >= 0",
          consistency_level: :Strong
        )
        |> Enum.to_list()

      assert length(hits) >= 16_385
      ids = Enum.map(hits, & &1.id)
      assert ids == Enum.uniq(ids)
    end

    test ":limit cap respected", %{conn: conn} do
      name = unique_collection_name("stream_limit")
      on_exit(fn -> cleanup_collection(conn, name) end)

      setup_vector_collection(conn, name, dim: 4, total: 5_000)

      hits =
        Milvex.search_stream(conn, name, [0.1, 0.2, 0.3, 0.4],
          vector_field: "embedding",
          batch_size: 200,
          limit: 1234,
          consistency_level: :Strong
        )
        |> Enum.to_list()

      assert length(hits) == 1234
    end

    test "empty result set", %{conn: conn} do
      name = unique_collection_name("stream_empty")
      on_exit(fn -> cleanup_collection(conn, name) end)

      setup_vector_collection(conn, name, dim: 4, total: 100)

      hits =
        Milvex.search_stream(conn, name, [0.1, 0.2, 0.3, 0.4],
          vector_field: "embedding",
          filter: "id > 999999",
          consistency_level: :Strong
        )
        |> Enum.to_list()

      assert hits == []
    end
  end

  describe "query_stream/4 (integration)" do
    test "walks all rows of a filter", %{conn: conn} do
      name = unique_collection_name("query_stream_filter")
      on_exit(fn -> cleanup_collection(conn, name) end)

      setup_vector_collection(conn, name, dim: 4, total: 10_000)

      rows =
        Milvex.query_stream(conn, name, "id < 5000",
          output_fields: ["id"],
          batch_size: 500,
          consistency_level: :Strong
        )
        |> Enum.to_list()

      assert length(rows) == 5_000
      ids = Enum.map(rows, & &1["id"])
      assert ids == Enum.uniq(ids)
    end
  end

  describe "search/4 offset+limit cap (integration)" do
    test "over-cap returns clear Invalid error", %{conn: conn} do
      name = unique_collection_name("offset_cap")
      on_exit(fn -> cleanup_collection(conn, name) end)

      setup_vector_collection(conn, name, dim: 4, total: 100)

      assert {:error, %Milvex.Errors.Invalid{} = error} =
               Milvex.search(conn, name, [[0.1, 0.2, 0.3, 0.4]],
                 vector_field: "embedding",
                 offset: 16_000,
                 limit: 500
               )

      message = Exception.message(error)
      assert message =~ "16384"
      assert message =~ "search_stream"
    end
  end
end
