defmodule Milvex.ExprParamsIntegrationTest do
  use ExUnit.Case, async: true
  use Mimic

  alias Milvex.Connection
  alias Milvex.ExprParams
  alias Milvex.Milvus.Proto.Common.Status
  alias Milvex.Milvus.Proto.Milvus.MutationResult
  alias Milvex.Milvus.Proto.Milvus.QueryResults
  alias Milvex.RPC

  setup :verify_on_exit!

  describe "query/4 with expr_params" do
    test "populates expr_template_values on QueryRequest" do
      params = %{"min_year" => 2020, "genres" => ["action", "sci-fi"]}
      expected_proto = ExprParams.to_proto(params)

      stub(Connection, :get_channel, fn _, _ -> {:ok, :channel, Milvex.Config.defaults()} end)

      expect(RPC, :call, fn _channel_fn, _, :query, request, _opts ->
        assert request.expr == "year > {min_year} AND genre IN {genres}"
        assert request.expr_template_values == expected_proto
        {:ok, %QueryResults{status: %Status{code: 0}, fields_data: []}}
      end)

      Milvex.query(:conn, "movies", "year > {min_year} AND genre IN {genres}",
        expr_params: params
      )
    end

    test "leaves expr_template_values empty when no expr_params" do
      stub(Connection, :get_channel, fn _, _ -> {:ok, :channel, Milvex.Config.defaults()} end)

      expect(RPC, :call, fn _channel_fn, _, :query, request, _opts ->
        assert request.expr_template_values == %{}
        {:ok, %QueryResults{status: %Status{code: 0}, fields_data: []}}
      end)

      Milvex.query(:conn, "movies", "year > 2020")
    end
  end

  describe "delete/3 with expr_params" do
    test "populates expr_template_values on DeleteRequest" do
      params = %{"cutoff" => 2000}
      expected_proto = ExprParams.to_proto(params)

      stub(Connection, :get_channel, fn _, _ -> {:ok, :channel, Milvex.Config.defaults()} end)

      expect(RPC, :call, fn _channel_fn, _, :delete, request, _opts ->
        assert request.expr == "year < {cutoff}"
        assert request.expr_template_values == expected_proto
        {:ok, %MutationResult{status: %Status{code: 0}, delete_cnt: 5}}
      end)

      Milvex.delete(:conn, "movies", "year < {cutoff}", expr_params: params)
    end

    test "leaves expr_template_values empty when no expr_params" do
      stub(Connection, :get_channel, fn _, _ -> {:ok, :channel, Milvex.Config.defaults()} end)

      expect(RPC, :call, fn _channel_fn, _, :delete, request, _opts ->
        assert request.expr_template_values == %{}
        {:ok, %MutationResult{status: %Status{code: 0}, delete_cnt: 0}}
      end)

      Milvex.delete(:conn, "movies", "id in [1, 2, 3]")
    end
  end
end
