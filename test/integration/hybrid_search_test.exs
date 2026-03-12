defmodule Milvex.Integration.HybridSearchTest do
  use Milvex.IntegrationCase

  alias Milvex.AnnSearch
  alias Milvex.Index
  alias Milvex.Ranker
  alias Milvex.Schema
  alias Milvex.Schema.Field

  @moduletag :integration
  @collection_name "hybrid_search_test"

  setup %{conn: conn} do
    on_exit(fn ->
      Milvex.drop_collection(conn, @collection_name)
    end)

    schema =
      Schema.build!(
        name: @collection_name,
        fields: [
          Field.primary_key("id", :int64, auto_id: true),
          Field.varchar("title", 512),
          Field.scalar("timestamp", :int64),
          Field.vector("text_embedding", 4),
          Field.vector("image_embedding", 4)
        ]
      )

    :ok = Milvex.create_collection(conn, @collection_name, schema)

    :ok = Milvex.create_index(conn, @collection_name, Index.autoindex("text_embedding", :cosine))
    :ok = Milvex.create_index(conn, @collection_name, Index.autoindex("image_embedding", :cosine))

    :ok = Milvex.load_collection(conn, @collection_name)

    now = System.os_time(:second)

    data = [
      %{
        title: "Red shirt",
        timestamp: now,
        text_embedding: [1.0, 0.0, 0.0, 0.0],
        image_embedding: [0.0, 1.0, 0.0, 0.0]
      },
      %{
        title: "Blue pants",
        timestamp: now - 86_400,
        text_embedding: [0.0, 1.0, 0.0, 0.0],
        image_embedding: [0.0, 0.0, 1.0, 0.0]
      },
      %{
        title: "Green hat",
        timestamp: now - 172_800,
        text_embedding: [0.0, 0.0, 1.0, 0.0],
        image_embedding: [1.0, 0.0, 0.0, 0.0]
      }
    ]

    {:ok, _} = Milvex.insert(conn, @collection_name, data)

    Process.sleep(1000)

    {:ok, conn: conn, now: now}
  end

  describe "hybrid_search/5" do
    test "searches across multiple vector fields with weighted ranker", %{conn: conn} do
      {:ok, text_search} = AnnSearch.new("text_embedding", [[1.0, 0.0, 0.0, 0.0]], limit: 3)
      {:ok, image_search} = AnnSearch.new("image_embedding", [[0.0, 1.0, 0.0, 0.0]], limit: 3)
      {:ok, ranker} = Ranker.weighted([0.5, 0.5])

      {:ok, results} =
        Milvex.hybrid_search(conn, @collection_name, [text_search, image_search], ranker,
          output_fields: ["title"],
          limit: 3
        )

      refute Enum.empty?(results.hits)
    end

    test "searches with RRF ranker", %{conn: conn} do
      {:ok, text_search} = AnnSearch.new("text_embedding", [[1.0, 0.0, 0.0, 0.0]], limit: 3)
      {:ok, image_search} = AnnSearch.new("image_embedding", [[0.0, 1.0, 0.0, 0.0]], limit: 3)
      {:ok, ranker} = Ranker.rrf(k: 60)

      {:ok, results} =
        Milvex.hybrid_search(conn, @collection_name, [text_search, image_search], ranker,
          output_fields: ["title"],
          limit: 3
        )

      refute Enum.empty?(results.hits)
    end

    test "searches with decay ranker", %{conn: conn, now: now} do
      {:ok, text_search} = AnnSearch.new("text_embedding", [[1.0, 0.0, 0.0, 0.0]], limit: 3)
      {:ok, image_search} = AnnSearch.new("image_embedding", [[0.0, 1.0, 0.0, 0.0]], limit: 3)
      {:ok, ranker} = Ranker.decay(:gauss, field: "timestamp", origin: now, scale: 86_400)

      {:ok, results} =
        Milvex.hybrid_search(conn, @collection_name, [text_search, image_search], ranker,
          output_fields: ["title", "timestamp"],
          limit: 3
        )

      refute Enum.empty?(results.hits)
    end

    test "searches with decay ranker on timestamptz field", %{conn: conn} do
      collection = "hybrid_search_decay_tz_test"

      on_exit(fn ->
        Milvex.drop_collection(conn, collection)
      end)

      schema =
        Schema.build!(
          name: collection,
          fields: [
            Field.primary_key("id", :int64, auto_id: true),
            Field.varchar("title", 512),
            Field.timestamp("created_at"),
            Field.vector("text_embedding", 4),
            Field.vector("image_embedding", 4)
          ]
        )

      :ok = Milvex.create_collection(conn, collection, schema)
      :ok = Milvex.create_index(conn, collection, Index.autoindex("text_embedding", :cosine))
      :ok = Milvex.create_index(conn, collection, Index.autoindex("image_embedding", :cosine))
      :ok = Milvex.load_collection(conn, collection)

      now = DateTime.utc_now()
      one_day_ago = DateTime.add(now, -86_400, :second)
      two_days_ago = DateTime.add(now, -172_800, :second)

      data = [
        %{
          title: "Recent",
          created_at: now,
          text_embedding: [1.0, 0.0, 0.0, 0.0],
          image_embedding: [0.0, 1.0, 0.0, 0.0]
        },
        %{
          title: "Yesterday",
          created_at: one_day_ago,
          text_embedding: [0.0, 1.0, 0.0, 0.0],
          image_embedding: [0.0, 0.0, 1.0, 0.0]
        },
        %{
          title: "Old",
          created_at: two_days_ago,
          text_embedding: [0.0, 0.0, 1.0, 0.0],
          image_embedding: [1.0, 0.0, 0.0, 0.0]
        }
      ]

      {:ok, _} = Milvex.insert(conn, collection, data)
      Process.sleep(1000)

      origin = DateTime.to_unix(now)

      {:ok, text_search} = AnnSearch.new("text_embedding", [[1.0, 0.0, 0.0, 0.0]], limit: 3)
      {:ok, image_search} = AnnSearch.new("image_embedding", [[0.0, 1.0, 0.0, 0.0]], limit: 3)
      {:ok, ranker} = Ranker.decay(:exp, field: "created_at", origin: origin, scale: 86_400)

      {:ok, results} =
        Milvex.hybrid_search(conn, collection, [text_search, image_search], ranker,
          output_fields: ["title", "created_at"],
          limit: 3
        )

      refute Enum.empty?(results.hits)
    end

    test "applies filter expression", %{conn: conn} do
      filter = "title like 'Red%'"

      {:ok, text_search} =
        AnnSearch.new("text_embedding", [[1.0, 0.0, 0.0, 0.0]],
          limit: 3,
          expr: filter
        )

      {:ok, image_search} =
        AnnSearch.new("image_embedding", [[0.0, 1.0, 0.0, 0.0]],
          limit: 3,
          expr: filter
        )

      {:ok, ranker} = Ranker.rrf()

      {:ok, results} =
        Milvex.hybrid_search(conn, @collection_name, [text_search, image_search], ranker,
          output_fields: ["title"],
          limit: 3
        )

      for hit <- List.flatten(results.hits) do
        if hit.fields["title"] do
          assert String.starts_with?(hit.fields["title"], "Red")
        end
      end
    end
  end
end
