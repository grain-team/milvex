defmodule Milvex.SearchTest do
  use ExUnit.Case
  use Mimic

  alias Milvex.Connection
  alias Milvex.Highlighter
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
                            %FieldSchema{
                              name: "id",
                              data_type: :Int64,
                              is_primary_key: true
                            },
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

  @search_response {:ok,
                    %SearchResults{
                      status: %Status{code: 0},
                      results: nil,
                      collection_name: "test"
                    }}

  setup :verify_on_exit!

  describe "search/4 with highlight option" do
    test "includes highlighter in SearchRequest when highlight option is provided" do
      {:ok, highlighter} = Highlighter.lexical("text_field")
      test_pid = self()

      stub(Connection, :get_channel, fn _conn, _opts -> {:ok, @channel} end)

      stub(RPC, :call, fn _channel, _stub, method, request ->
        case method do
          :describe_collection ->
            @describe_response

          :search ->
            send(test_pid, {:search_request, request})
            @search_response
        end
      end)

      assert {:ok, _result} =
               Milvex.search(:conn, "test", [[0.1, 0.2, 0.3, 0.4]],
                 vector_field: "embedding",
                 highlight: highlighter
               )

      assert_received {:search_request, request}
      assert request.highlighter != nil
      assert request.highlighter.type == :Lexical

      params = request.highlighter.params
      pre_tags = Enum.find(params, &(&1.key == "pre_tags"))
      post_tags = Enum.find(params, &(&1.key == "post_tags"))

      assert pre_tags.value == Jason.encode!(["<b>"])
      assert post_tags.value == Jason.encode!(["</b>"])
    end

    test "sends nil highlighter when highlight option is not provided" do
      test_pid = self()

      stub(Connection, :get_channel, fn _conn, _opts -> {:ok, @channel} end)

      stub(RPC, :call, fn _channel, _stub, method, request ->
        case method do
          :describe_collection ->
            @describe_response

          :search ->
            send(test_pid, {:search_request, request})
            @search_response
        end
      end)

      assert {:ok, _result} =
               Milvex.search(:conn, "test", [[0.1, 0.2, 0.3, 0.4]], vector_field: "embedding")

      assert_received {:search_request, request}
      assert request.highlighter == nil
    end

    test "supports custom pre_tag and post_tag" do
      {:ok, highlighter} = Highlighter.lexical("text_field", pre_tag: "<em>", post_tag: "</em>")
      test_pid = self()

      stub(Connection, :get_channel, fn _conn, _opts -> {:ok, @channel} end)

      stub(RPC, :call, fn _channel, _stub, method, request ->
        case method do
          :describe_collection ->
            @describe_response

          :search ->
            send(test_pid, {:search_request, request})
            @search_response
        end
      end)

      assert {:ok, _result} =
               Milvex.search(:conn, "test", [[0.1, 0.2, 0.3, 0.4]],
                 vector_field: "embedding",
                 highlight: highlighter
               )

      assert_received {:search_request, request}
      params = request.highlighter.params
      pre_tags = Enum.find(params, &(&1.key == "pre_tags"))
      post_tags = Enum.find(params, &(&1.key == "post_tags"))

      assert pre_tags.value == Jason.encode!(["<em>"])
      assert post_tags.value == Jason.encode!(["</em>"])
    end
  end

  describe "search/4 with pagination and grouping options" do
    test "offset is included in search_params" do
      test_pid = self()

      stub(Connection, :get_channel, fn _conn, _opts -> {:ok, @channel} end)

      stub(RPC, :call, fn _channel, _stub, method, request ->
        case method do
          :describe_collection ->
            @describe_response

          :search ->
            send(test_pid, {:search_request, request})
            @search_response
        end
      end)

      assert {:ok, _result} =
               Milvex.search(:conn, "test", [[0.1, 0.2, 0.3, 0.4]],
                 vector_field: "embedding",
                 offset: 20
               )

      assert_received {:search_request, request}
      offset_param = Enum.find(request.search_params, &(&1.key == "offset"))
      assert offset_param != nil
      assert offset_param.value == "20"
    end

    test "grouping params are included in search_params" do
      test_pid = self()

      stub(Connection, :get_channel, fn _conn, _opts -> {:ok, @channel} end)

      stub(RPC, :call, fn _channel, _stub, method, request ->
        case method do
          :describe_collection ->
            @describe_response

          :search ->
            send(test_pid, {:search_request, request})
            @search_response
        end
      end)

      assert {:ok, _result} =
               Milvex.search(:conn, "test", [[0.1, 0.2, 0.3, 0.4]],
                 vector_field: "embedding",
                 group_by_field: "category",
                 group_size: 3,
                 strict_group_size: true
               )

      assert_received {:search_request, request}
      params = request.search_params

      group_by = Enum.find(params, &(&1.key == "group_by_field"))
      assert group_by.value == "category"

      group_size = Enum.find(params, &(&1.key == "group_size"))
      assert group_size.value == "3"

      strict = Enum.find(params, &(&1.key == "strict_group_size"))
      assert strict.value == "true"
    end

    test "round_decimal and ignore_growing are included in search_params" do
      test_pid = self()

      stub(Connection, :get_channel, fn _conn, _opts -> {:ok, @channel} end)

      stub(RPC, :call, fn _channel, _stub, method, request ->
        case method do
          :describe_collection ->
            @describe_response

          :search ->
            send(test_pid, {:search_request, request})
            @search_response
        end
      end)

      assert {:ok, _result} =
               Milvex.search(:conn, "test", [[0.1, 0.2, 0.3, 0.4]],
                 vector_field: "embedding",
                 round_decimal: 4,
                 ignore_growing: true
               )

      assert_received {:search_request, request}
      params = request.search_params

      round_dec = Enum.find(params, &(&1.key == "round_decimal"))
      assert round_dec.value == "4"

      ignore = Enum.find(params, &(&1.key == "ignore_growing"))
      assert ignore.value == "true"
    end

    test "optional params are omitted when not provided" do
      test_pid = self()

      stub(Connection, :get_channel, fn _conn, _opts -> {:ok, @channel} end)

      stub(RPC, :call, fn _channel, _stub, method, request ->
        case method do
          :describe_collection ->
            @describe_response

          :search ->
            send(test_pid, {:search_request, request})
            @search_response
        end
      end)

      assert {:ok, _result} =
               Milvex.search(:conn, "test", [[0.1, 0.2, 0.3, 0.4]], vector_field: "embedding")

      assert_received {:search_request, request}
      params = request.search_params

      assert Enum.find(params, &(&1.key == "offset")) == nil
      assert Enum.find(params, &(&1.key == "group_by_field")) == nil
      assert Enum.find(params, &(&1.key == "group_size")) == nil
      assert Enum.find(params, &(&1.key == "strict_group_size")) == nil
      assert Enum.find(params, &(&1.key == "round_decimal")) == nil
      assert Enum.find(params, &(&1.key == "ignore_growing")) == nil
    end
  end
end
