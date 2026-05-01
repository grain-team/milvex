defmodule Milvex.IteratorTest do
  use ExUnit.Case, async: true
  use Mimic

  @moduletag :capture_log

  alias Milvex.Connection
  alias Milvex.Errors.Grpc
  alias Milvex.Errors.Invalid
  alias Milvex.RPC

  alias Milvex.Milvus.Proto.Common.KeyValuePair
  alias Milvex.Milvus.Proto.Common.Status
  alias Milvex.Milvus.Proto.Milvus.DescribeCollectionResponse
  alias Milvex.Milvus.Proto.Milvus.QueryResults
  alias Milvex.Milvus.Proto.Milvus.SearchResults
  alias Milvex.Milvus.Proto.Schema.CollectionSchema
  alias Milvex.Milvus.Proto.Schema.FieldData
  alias Milvex.Milvus.Proto.Schema.FieldSchema
  alias Milvex.Milvus.Proto.Schema.IDs
  alias Milvex.Milvus.Proto.Schema.LongArray
  alias Milvex.Milvus.Proto.Schema.ScalarField
  alias Milvex.Milvus.Proto.Schema.SearchIteratorV2Results
  alias Milvex.Milvus.Proto.Schema.SearchResultData

  @channel %GRPC.Channel{host: "localhost", port: 19_530}
  @config Milvex.Config.defaults()

  @describe_response {:ok,
                      %DescribeCollectionResponse{
                        status: %Status{code: 0},
                        schema: %CollectionSchema{
                          name: "test",
                          fields: [
                            %FieldSchema{name: "id", data_type: :Int64, is_primary_key: true},
                            %FieldSchema{
                              name: "embedding",
                              data_type: :FloatVector,
                              type_params: [%KeyValuePair{key: "dim", value: "4"}]
                            }
                          ]
                        },
                        collectionID: 1,
                        shards_num: 1,
                        consistency_level: :Bounded,
                        created_timestamp: 0,
                        aliases: []
                      }}

  setup :verify_on_exit!

  defp fake_search_response(ids, opts \\ []) do
    token = Keyword.get(opts, :token, "tok-#{:erlang.unique_integer([:positive])}")
    last_bound = Keyword.get(opts, :last_bound, 0.5)
    session_ts = Keyword.get(opts, :session_ts, 1_700_000_000)

    iter =
      if Keyword.get(opts, :nil_iter, false),
        do: nil,
        else: %SearchIteratorV2Results{token: token, last_bound: last_bound}

    {:ok,
     %SearchResults{
       status: %Status{code: 0},
       results: %SearchResultData{
         num_queries: 1,
         top_k: length(ids),
         topks: [length(ids)],
         ids: %IDs{id_field: {:int_id, %LongArray{data: ids}}},
         scores: Enum.map(ids, fn _ -> 0.9 end),
         search_iterator_v2_results: iter
       },
       collection_name: "test",
       session_ts: session_ts
     }}
  end

  defp stub_channel_and_describe do
    stub(Connection, :get_channel, fn _conn, _opts -> {:ok, @channel, @config} end)

    stub(RPC, :call, fn _ch, _stub, :describe_collection, _req, _opts -> @describe_response end)
  end

  describe "search_stream/4 eager validation" do
    test "rejects multi-vector input at the wrapper" do
      stub_channel_and_describe()

      assert_raise Invalid, ~r/single vector/, fn ->
        Milvex.search_stream(:conn, "test", [[0.1, 0.2, 0.3, 0.4], [0.5, 0.6, 0.7, 0.8]],
          vector_field: "embedding"
        )
      end
    end

    test "rejects empty vector" do
      assert_raise Invalid, ~r/non-empty/, fn ->
        Milvex.search_stream(:conn, "test", [], vector_field: "embedding")
      end
    end

    test "rejects missing :vector_field" do
      assert_raise Invalid, ~r/vector_field is required/, fn ->
        Milvex.search_stream(:conn, "test", [0.1, 0.2, 0.3, 0.4], [])
      end
    end

    test "rejects :offset" do
      assert_raise Invalid, ~r/offset/, fn ->
        Milvex.search_stream(:conn, "test", [0.1, 0.2, 0.3, 0.4],
          vector_field: "embedding",
          offset: 10
        )
      end
    end

    test "rejects :batch_size out of range" do
      assert_raise Invalid, fn ->
        Milvex.search_stream(:conn, "test", [0.1, 0.2, 0.3, 0.4],
          vector_field: "embedding",
          batch_size: 0
        )
      end

      assert_raise Invalid, fn ->
        Milvex.search_stream(:conn, "test", [0.1, 0.2, 0.3, 0.4],
          vector_field: "embedding",
          batch_size: 20_000
        )
      end
    end

    test "rejects :group_by_field, :top_k, etc." do
      for key <- [:top_k, :group_by_field, :group_size, :strict_group_size] do
        assert_raise Invalid, fn ->
          Milvex.search_stream(
            :conn,
            "test",
            [0.1, 0.2, 0.3, 0.4],
            [{:vector_field, "embedding"}, {key, 1}]
          )
        end
      end
    end

    test "validation runs before stream construction (no RPC issued)" do
      reject(&RPC.call/5)

      assert_raise Invalid, fn ->
        Milvex.search_stream(:conn, "test", [], vector_field: "embedding")
      end
    end
  end

  describe "search_stream/4 batching" do
    test "streams across two batches and halts on empty third" do
      test_pid = self()
      stub_channel_and_describe()
      counter = :counters.new(1, [])

      stub(RPC, :call, fn
        _ch, _stub, :describe_collection, _req, _opts ->
          @describe_response

        _ch, _stub, :search, request, _opts ->
          :counters.add(counter, 1, 1)
          n = :counters.get(counter, 1)
          send(test_pid, {:search, n, request})

          case n do
            1 -> fake_search_response([1, 2, 3], token: "t1", last_bound: 0.7)
            2 -> fake_search_response([4, 5], token: "t2", last_bound: 0.5)
            _ -> fake_search_response([])
          end
      end)

      hits =
        Milvex.search_stream(:conn, "test", [0.1, 0.2, 0.3, 0.4],
          vector_field: "embedding",
          batch_size: 3
        )
        |> Enum.to_list()

      assert Enum.map(hits, & &1.id) == [1, 2, 3, 4, 5]

      assert_received {:search, 1, _req1}
      assert_received {:search, 2, req2}
      assert_received {:search, 3, _req3}

      params = Map.new(req2.search_params, &{&1.key, &1.value})
      assert params["search_iter_id"] == "t1"
      assert params["search_iter_last_bound"] == "0.7"
      assert params["search_iter_v2"] == "true"
      assert params["search_iter_batch_size"] == "3"
      assert params["topk"] == "3"
    end

    test "pins session_ts from first response into guarantee_timestamp on subsequent calls" do
      test_pid = self()
      stub_channel_and_describe()
      counter = :counters.new(1, [])

      stub(RPC, :call, fn
        _ch, _stub, :describe_collection, _req, _opts ->
          @describe_response

        _ch, _stub, :search, request, _opts ->
          :counters.add(counter, 1, 1)
          n = :counters.get(counter, 1)
          send(test_pid, {:search, n, request})

          case n do
            1 -> fake_search_response([1], session_ts: 42, token: "t1")
            _ -> fake_search_response([])
          end
      end)

      Milvex.search_stream(:conn, "test", [0.1, 0.2, 0.3, 0.4],
        vector_field: "embedding",
        batch_size: 1
      )
      |> Enum.to_list()

      assert_received {:search, 1, req1}
      assert_received {:search, 2, req2}
      assert req1.guarantee_timestamp in [0, nil]
      assert req2.guarantee_timestamp == 42
    end

    test ":limit truncates mid-batch" do
      stub_channel_and_describe()

      stub(RPC, :call, fn
        _ch, _stub, :describe_collection, _req, _opts -> @describe_response
        _ch, _stub, :search, _req, _opts -> fake_search_response([1, 2, 3, 4, 5])
      end)

      hits =
        Milvex.search_stream(:conn, "test", [0.1, 0.2, 0.3, 0.4],
          vector_field: "embedding",
          batch_size: 5,
          limit: 3
        )
        |> Enum.to_list()

      assert Enum.map(hits, & &1.id) == [1, 2, 3]
    end

    test "Stream.take halts after first batch" do
      stub_channel_and_describe()
      counter = :counters.new(1, [])

      stub(RPC, :call, fn
        _ch, _stub, :describe_collection, _req, _opts ->
          @describe_response

        _ch, _stub, :search, _req, _opts ->
          :counters.add(counter, 1, 1)
          fake_search_response([1, 2, 3, 4, 5])
      end)

      Milvex.search_stream(:conn, "test", [0.1, 0.2, 0.3, 0.4],
        vector_field: "embedding",
        batch_size: 5
      )
      |> Enum.take(2)

      assert :counters.get(counter, 1) == 1
    end
  end

  describe "search_stream/4 first-response gating" do
    test "non-empty hits + nil iterator metadata raises (server < 2.4)" do
      stub_channel_and_describe()

      stub(RPC, :call, fn
        _ch, _stub, :describe_collection, _req, _opts -> @describe_response
        _ch, _stub, :search, _req, _opts -> fake_search_response([1], nil_iter: true)
      end)

      assert_raise Invalid, ~r/V2 not supported/, fn ->
        Milvex.search_stream(:conn, "test", [0.1, 0.2, 0.3, 0.4], vector_field: "embedding")
        |> Enum.to_list()
      end
    end

    test "empty hits + nil iterator metadata halts cleanly" do
      stub_channel_and_describe()

      stub(RPC, :call, fn
        _ch, _stub, :describe_collection, _req, _opts -> @describe_response
        _ch, _stub, :search, _req, _opts -> fake_search_response([], nil_iter: true)
      end)

      assert [] =
               Milvex.search_stream(:conn, "test", [0.1, 0.2, 0.3, 0.4],
                 vector_field: "embedding"
               )
               |> Enum.to_list()
    end

    test "empty hits + present iterator metadata halts cleanly" do
      stub_channel_and_describe()

      stub(RPC, :call, fn
        _ch, _stub, :describe_collection, _req, _opts -> @describe_response
        _ch, _stub, :search, _req, _opts -> fake_search_response([])
      end)

      assert [] =
               Milvex.search_stream(:conn, "test", [0.1, 0.2, 0.3, 0.4],
                 vector_field: "embedding"
               )
               |> Enum.to_list()
    end
  end

  describe "search_stream/4 session_ts == 0 handling" do
    test "raises on :Strong with session_ts == 0" do
      stub_channel_and_describe()

      stub(RPC, :call, fn
        _ch, _stub, :describe_collection, _req, _opts -> @describe_response
        _ch, _stub, :search, _req, _opts -> fake_search_response([1], session_ts: 0)
      end)

      assert_raise Invalid, ~r/cannot pin MVCC/, fn ->
        Milvex.search_stream(:conn, "test", [0.1, 0.2, 0.3, 0.4],
          vector_field: "embedding",
          consistency_level: :Strong
        )
        |> Enum.to_list()
      end
    end

    test "proceeds on :Eventually with session_ts == 0 (guarantee_timestamp not set)" do
      test_pid = self()
      stub_channel_and_describe()
      counter = :counters.new(1, [])

      stub(RPC, :call, fn
        _ch, _stub, :describe_collection, _req, _opts ->
          @describe_response

        _ch, _stub, :search, request, _opts ->
          :counters.add(counter, 1, 1)
          n = :counters.get(counter, 1)
          send(test_pid, {:search, n, request})

          case n do
            1 -> fake_search_response([1], session_ts: 0, token: "t1")
            _ -> fake_search_response([])
          end
      end)

      Milvex.search_stream(:conn, "test", [0.1, 0.2, 0.3, 0.4],
        vector_field: "embedding",
        consistency_level: :Eventually
      )
      |> Enum.to_list()

      assert_received {:search, 2, req2}
      assert req2.guarantee_timestamp in [0, nil]
    end
  end

  describe "search_stream/4 error propagation" do
    test "RPC transport error raises" do
      stub_channel_and_describe()

      stub(RPC, :call, fn
        _ch, _stub, :describe_collection, _req, _opts ->
          @describe_response

        _ch, _stub, :search, _req, _opts ->
          {:error, Grpc.exception(message: "transport down", operation: "Search")}
      end)

      assert_raise Grpc, fn ->
        Milvex.search_stream(:conn, "test", [0.1, 0.2, 0.3, 0.4], vector_field: "embedding")
        |> Enum.to_list()
      end
    end

    test "RPC status error raises" do
      stub_channel_and_describe()

      stub(RPC, :call, fn
        _ch, _stub, :describe_collection, _req, _opts ->
          @describe_response

        _ch, _stub, :search, _req, _opts ->
          {:ok,
           %SearchResults{
             status: %Status{code: 5, reason: "collection not loaded"},
             results: nil,
             collection_name: "test",
             session_ts: 0
           }}
      end)

      assert_raise Grpc, fn ->
        Milvex.search_stream(:conn, "test", [0.1, 0.2, 0.3, 0.4], vector_field: "embedding")
        |> Enum.to_list()
      end
    end
  end

  describe "search_stream/4 stream re-runnability" do
    test "consuming the same stream value twice issues two independent RPC sequences" do
      stub_channel_and_describe()
      counter = :counters.new(1, [])

      stub(RPC, :call, fn
        _ch, _stub, :describe_collection, _req, _opts ->
          @describe_response

        _ch, _stub, :search, _req, _opts ->
          :counters.add(counter, 1, 1)

          case rem(:counters.get(counter, 1), 2) do
            1 -> fake_search_response([1])
            0 -> fake_search_response([])
          end
      end)

      stream =
        Milvex.search_stream(:conn, "test", [0.1, 0.2, 0.3, 0.4], vector_field: "embedding")

      _ = Enum.to_list(stream)
      _ = Enum.to_list(stream)
      assert :counters.get(counter, 1) == 4
    end
  end

  defp fake_query_response(ids, opts \\ []) do
    session_ts = Keyword.get(opts, :session_ts, 1_700_000_000)

    {:ok,
     %QueryResults{
       status: %Status{code: 0},
       fields_data: [
         %FieldData{
           field_name: "id",
           type: :Int64,
           field: {:scalars, %ScalarField{data: {:long_data, %LongArray{data: ids}}}}
         }
       ],
       collection_name: "test",
       output_fields: ["id"],
       session_ts: session_ts,
       primary_field_name: "id"
     }}
  end

  defp stub_channel_only do
    stub(Connection, :get_channel, fn _conn, _opts -> {:ok, @channel, @config} end)
  end

  describe "query_stream/4 eager validation" do
    test "rejects non-binary expr" do
      reject(&RPC.call/5)

      assert_raise Invalid, ~r/expr/, fn ->
        Milvex.query_stream(:conn, "test", nil)
      end
    end

    test "rejects empty expr" do
      reject(&RPC.call/5)

      assert_raise Invalid, ~r/expr/, fn ->
        Milvex.query_stream(:conn, "test", "")
      end
    end

    test "rejects :offset" do
      reject(&RPC.call/5)

      assert_raise Invalid, ~r/offset/, fn ->
        Milvex.query_stream(:conn, "test", "id > 0", offset: 10)
      end
    end

    test "rejects :batch_size out of range" do
      reject(&RPC.call/5)

      assert_raise Invalid, fn ->
        Milvex.query_stream(:conn, "test", "id > 0", batch_size: 0)
      end

      assert_raise Invalid, fn ->
        Milvex.query_stream(:conn, "test", "id > 0", batch_size: 20_000)
      end
    end

    test "rejects non-positive :limit" do
      reject(&RPC.call/5)

      assert_raise Invalid, fn ->
        Milvex.query_stream(:conn, "test", "id > 0", limit: 0)
      end

      assert_raise Invalid, fn ->
        Milvex.query_stream(:conn, "test", "id > 0", limit: -5)
      end
    end

    test "validation runs before stream construction (no RPC issued)" do
      reject(&RPC.call/5)

      assert_raise Invalid, fn ->
        Milvex.query_stream(:conn, "test", "")
      end
    end
  end

  describe "query_stream/4 batching" do
    test "streams across two batches and halts on empty third" do
      test_pid = self()
      stub_channel_only()
      counter = :counters.new(1, [])

      stub(RPC, :call, fn
        _ch, _stub, :query, request, _opts ->
          :counters.add(counter, 1, 1)
          n = :counters.get(counter, 1)
          send(test_pid, {:query, n, request})

          case n do
            1 -> fake_query_response([1, 2, 3])
            2 -> fake_query_response([4, 5])
            _ -> fake_query_response([])
          end
      end)

      rows =
        Milvex.query_stream(:conn, "test", "id >= 0",
          output_fields: ["id"],
          batch_size: 3
        )
        |> Enum.to_list()

      assert Enum.map(rows, & &1["id"]) == [1, 2, 3, 4, 5]

      assert_received {:query, 1, req1}
      assert_received {:query, 2, req2}
      assert_received {:query, 3, _req3}

      params1 = Map.new(req1.query_params, &{&1.key, &1.value})
      assert params1["iterator"] == "True"
      assert params1["limit"] == "3"
      refute Map.has_key?(params1, "query_iter_last_pk")
      assert req1.expr == "id >= 0"

      params2 = Map.new(req2.query_params, &{&1.key, &1.value})
      assert params2["iterator"] == "True"
      assert params2["limit"] == "3"
      assert params2["query_iter_last_pk"] == "3"
      assert req2.expr == "(id >= 0) and id > 3"
    end

    test "pins session_ts from first response into guarantee_timestamp on subsequent calls" do
      test_pid = self()
      stub_channel_only()
      counter = :counters.new(1, [])

      stub(RPC, :call, fn
        _ch, _stub, :query, request, _opts ->
          :counters.add(counter, 1, 1)
          n = :counters.get(counter, 1)
          send(test_pid, {:query, n, request})

          case n do
            1 -> fake_query_response([1], session_ts: 42)
            _ -> fake_query_response([])
          end
      end)

      Milvex.query_stream(:conn, "test", "id >= 0",
        output_fields: ["id"],
        batch_size: 1
      )
      |> Enum.to_list()

      assert_received {:query, 1, req1}
      assert_received {:query, 2, req2}
      assert req1.guarantee_timestamp in [0, nil]
      assert req2.guarantee_timestamp == 42
    end

    test ":limit truncates mid-batch" do
      stub_channel_only()

      stub(RPC, :call, fn
        _ch, _stub, :query, _req, _opts -> fake_query_response([1, 2, 3, 4, 5])
      end)

      rows =
        Milvex.query_stream(:conn, "test", "id >= 0",
          output_fields: ["id"],
          batch_size: 5,
          limit: 3
        )
        |> Enum.to_list()

      assert Enum.map(rows, & &1["id"]) == [1, 2, 3]
    end

    test "Stream.take halts after first batch" do
      stub_channel_only()
      counter = :counters.new(1, [])

      stub(RPC, :call, fn
        _ch, _stub, :query, _req, _opts ->
          :counters.add(counter, 1, 1)
          fake_query_response([1, 2, 3, 4, 5])
      end)

      Milvex.query_stream(:conn, "test", "id >= 0",
        output_fields: ["id"],
        batch_size: 5
      )
      |> Enum.take(2)

      assert :counters.get(counter, 1) == 1
    end
  end

  describe "query_stream/4 session_ts == 0 handling" do
    test "raises on :Strong with session_ts == 0" do
      stub_channel_only()

      stub(RPC, :call, fn
        _ch, _stub, :query, _req, _opts -> fake_query_response([1], session_ts: 0)
      end)

      assert_raise Invalid, ~r/cannot pin MVCC/, fn ->
        Milvex.query_stream(:conn, "test", "id >= 0",
          output_fields: ["id"],
          consistency_level: :Strong
        )
        |> Enum.to_list()
      end
    end

    test "proceeds on :Eventually with session_ts == 0 (guarantee_timestamp not set)" do
      test_pid = self()
      stub_channel_only()
      counter = :counters.new(1, [])

      stub(RPC, :call, fn
        _ch, _stub, :query, request, _opts ->
          :counters.add(counter, 1, 1)
          n = :counters.get(counter, 1)
          send(test_pid, {:query, n, request})

          case n do
            1 -> fake_query_response([1], session_ts: 0)
            _ -> fake_query_response([])
          end
      end)

      Milvex.query_stream(:conn, "test", "id >= 0",
        output_fields: ["id"],
        consistency_level: :Eventually
      )
      |> Enum.to_list()

      assert_received {:query, 2, req2}
      assert req2.guarantee_timestamp in [0, nil]
    end
  end

  describe "query_stream/4 error propagation" do
    test "RPC transport error raises" do
      stub_channel_only()

      stub(RPC, :call, fn
        _ch, _stub, :query, _req, _opts ->
          {:error, Grpc.exception(message: "transport down", operation: "Query")}
      end)

      assert_raise Grpc, fn ->
        Milvex.query_stream(:conn, "test", "id >= 0", output_fields: ["id"])
        |> Enum.to_list()
      end
    end

    test "RPC status error raises" do
      stub_channel_only()

      stub(RPC, :call, fn
        _ch, _stub, :query, _req, _opts ->
          {:ok,
           %QueryResults{
             status: %Status{code: 5, reason: "collection not loaded"},
             fields_data: [],
             collection_name: "test",
             session_ts: 0,
             primary_field_name: "id"
           }}
      end)

      assert_raise Grpc, fn ->
        Milvex.query_stream(:conn, "test", "id >= 0", output_fields: ["id"])
        |> Enum.to_list()
      end
    end
  end

  describe "query_stream/4 stream re-runnability" do
    test "consuming the same stream value twice issues two independent RPC sequences" do
      stub_channel_only()
      counter = :counters.new(1, [])

      stub(RPC, :call, fn
        _ch, _stub, :query, _req, _opts ->
          :counters.add(counter, 1, 1)

          case rem(:counters.get(counter, 1), 2) do
            1 -> fake_query_response([1])
            0 -> fake_query_response([])
          end
      end)

      stream = Milvex.query_stream(:conn, "test", "id >= 0", output_fields: ["id"])

      _ = Enum.to_list(stream)
      _ = Enum.to_list(stream)
      assert :counters.get(counter, 1) == 4
    end
  end
end
