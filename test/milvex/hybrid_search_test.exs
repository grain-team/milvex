defmodule Milvex.HybridSearchTest do
  use ExUnit.Case, async: true
  use Mimic

  @moduletag :capture_log

  alias Milvex.AnnSearch
  alias Milvex.Connection
  alias Milvex.Ranker
  alias Milvex.RPC

  alias Milvex.Milvus.Proto.Common.KeyValuePair
  alias Milvex.Milvus.Proto.Common.Status
  alias Milvex.Milvus.Proto.Milvus.DescribeCollectionResponse
  alias Milvex.Milvus.Proto.Milvus.SearchResults
  alias Milvex.Milvus.Proto.Schema.CollectionSchema
  alias Milvex.Milvus.Proto.Schema.FieldSchema

  @channel %GRPC.Channel{host: "localhost", port: 19_530}

  @describe_response {:ok,
                      %DescribeCollectionResponse{
                        status: %Status{code: 0},
                        schema: %CollectionSchema{
                          name: "test",
                          fields: [
                            %FieldSchema{name: "id", data_type: :Int64, is_primary_key: true},
                            %FieldSchema{
                              name: "field1",
                              data_type: :FloatVector,
                              type_params: [%KeyValuePair{key: "dim", value: "2"}]
                            },
                            %FieldSchema{
                              name: "field2",
                              data_type: :FloatVector,
                              type_params: [%KeyValuePair{key: "dim", value: "2"}]
                            }
                          ]
                        },
                        collectionID: 1,
                        shards_num: 1,
                        consistency_level: :Bounded,
                        created_timestamp: 0,
                        aliases: []
                      }}

  @hybrid_search_response {:ok,
                           %SearchResults{
                             status: %Status{code: 0},
                             results: nil,
                             collection_name: "test"
                           }}

  setup :verify_on_exit!

  describe "hybrid_search/5 validation" do
    test "returns {:error, _} when searches is empty" do
      {:ok, ranker} = Ranker.rrf()
      assert {:error, error} = Milvex.hybrid_search(:conn, "collection", [], ranker)
      assert error.field == :searches
    end

    test "returns {:error, _} when weight count doesn't match search count" do
      {:ok, search1} = AnnSearch.new("field1", [[0.1, 0.2]], limit: 10)
      {:ok, search2} = AnnSearch.new("field2", [[0.3, 0.4]], limit: 10)
      {:ok, ranker} = Ranker.weighted([0.5])

      assert {:error, error} =
               Milvex.hybrid_search(:conn, "collection", [search1, search2], ranker)

      assert error.field == :weights
    end

    test "accepts matching weight count and search count" do
      {:ok, search1} = AnnSearch.new("field1", [[0.1, 0.2]], limit: 10)
      {:ok, search2} = AnnSearch.new("field2", [[0.3, 0.4]], limit: 10)
      {:ok, ranker} = Ranker.weighted([0.7, 0.3])

      stub(Connection, :get_channel, fn _, _ -> {:error, :not_connected} end)

      assert {:error, _} = Milvex.hybrid_search(:conn, "collection", [search1, search2], ranker)
    end

    test "RRF ranker doesn't require weight matching" do
      {:ok, search1} = AnnSearch.new("field1", [[0.1, 0.2]], limit: 10)
      {:ok, search2} = AnnSearch.new("field2", [[0.3, 0.4]], limit: 10)
      {:ok, ranker} = Ranker.rrf()

      stub(Connection, :get_channel, fn _, _ -> {:error, :not_connected} end)

      assert {:error, _} = Milvex.hybrid_search(:conn, "collection", [search1, search2], ranker)
    end

    test "DecayRanker doesn't require weight matching" do
      {:ok, search1} = AnnSearch.new("field1", [[0.1, 0.2]], limit: 10)
      {:ok, search2} = AnnSearch.new("field2", [[0.3, 0.4]], limit: 10)
      {:ok, ranker} = Ranker.decay(:gauss, field: "timestamp", origin: 1_000_000, scale: 3600)

      stub(Connection, :get_channel, fn _, _ -> {:error, :not_connected} end)

      assert {:error, _} = Milvex.hybrid_search(:conn, "collection", [search1, search2], ranker)
    end
  end

  describe "hybrid_search/5 rank_params" do
    test "includes offset in rank_params" do
      {:ok, search1} = AnnSearch.new("field1", [[0.1, 0.2]], limit: 10)
      {:ok, search2} = AnnSearch.new("field2", [[0.3, 0.4]], limit: 10)
      {:ok, ranker} = Ranker.rrf()
      test_pid = self()

      stub(Connection, :get_channel, fn _conn, _opts -> {:ok, @channel} end)

      stub(RPC, :call, fn _channel, _stub, method, request ->
        case method do
          :describe_collection ->
            @describe_response

          :hybrid_search ->
            send(test_pid, {:hybrid_search_request, request})
            @hybrid_search_response
        end
      end)

      assert {:ok, _result} =
               Milvex.hybrid_search(:conn, "test", [search1, search2], ranker,
                 limit: 20,
                 offset: 10
               )

      assert_received {:hybrid_search_request, request}

      rank_params = request.rank_params
      limit_param = Enum.find(rank_params, &(&1.key == "limit"))
      offset_param = Enum.find(rank_params, &(&1.key == "offset"))

      assert limit_param.value == "20"
      assert offset_param.value == "10"
    end

    test "includes grouping and misc params in rank_params" do
      {:ok, search1} = AnnSearch.new("field1", [[0.1, 0.2]], limit: 10)
      {:ok, search2} = AnnSearch.new("field2", [[0.3, 0.4]], limit: 10)
      {:ok, ranker} = Ranker.weighted([0.7, 0.3])
      test_pid = self()

      stub(Connection, :get_channel, fn _conn, _opts -> {:ok, @channel} end)

      stub(RPC, :call, fn _channel, _stub, method, request ->
        case method do
          :describe_collection ->
            @describe_response

          :hybrid_search ->
            send(test_pid, {:hybrid_search_request, request})
            @hybrid_search_response
        end
      end)

      assert {:ok, _result} =
               Milvex.hybrid_search(:conn, "test", [search1, search2], ranker,
                 limit: 10,
                 group_by_field: "category",
                 group_size: 3,
                 strict_group_size: true,
                 round_decimal: 4,
                 ignore_growing: true
               )

      assert_received {:hybrid_search_request, request}

      rank_params = request.rank_params

      find_param = fn key -> Enum.find(rank_params, &(&1.key == key)) end

      assert find_param.("limit").value == "10"
      assert find_param.("group_by_field").value == "category"
      assert find_param.("group_size").value == "3"
      assert find_param.("strict_group_size").value == "true"
      assert find_param.("round_decimal").value == "4"
      assert find_param.("ignore_growing").value == "true"
    end
  end
end
