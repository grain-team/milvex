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
end
