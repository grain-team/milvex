defmodule Milvex.Iterator do
  @moduledoc false

  alias Milvex.Config
  alias Milvex.Connection
  alias Milvex.Errors.Invalid
  alias Milvex.ExprParams
  alias Milvex.Internal
  alias Milvex.QueryResult
  alias Milvex.RPC
  alias Milvex.SearchResult

  alias Milvex.Milvus.Proto.Common.KeyValuePair

  alias Milvex.Milvus.Proto.Milvus.MilvusService
  alias Milvex.Milvus.Proto.Milvus.QueryRequest
  alias Milvex.Milvus.Proto.Milvus.SearchRequest

  @max_batch_size 16_384
  @default_batch_size 1_000

  @forbidden_search_opts [
    :group_by_field,
    :group_size,
    :strict_group_size,
    :top_k
  ]

  @query_iter_keys %{
    enable: "iterator",
    limit: "limit",
    last_pk: "query_iter_last_pk"
  }

  @doc false
  @spec search_stream(GenServer.server(), Milvex.collection_ref(), [number()], keyword()) ::
          Enumerable.t()
  def search_stream(conn, collection, vector, opts) do
    validate_search_input!(vector, opts)

    Stream.resource(
      fn -> start_search(conn, collection, vector, opts) end,
      &next_search/1,
      fn _state -> :ok end
    )
  end

  defp validate_search_input!(vector, opts) do
    cond do
      not is_list(vector) ->
        raise_invalid(:vector, "search_stream accepts a single vector (list of numbers)")

      vector == [] ->
        raise_invalid(:vector, "vector must be non-empty")

      Enum.any?(vector, &is_list/1) ->
        raise_invalid(
          :vector,
          "search_stream accepts a single vector; use search/4 with :offset for multi-vector"
        )

      not Keyword.has_key?(opts, :vector_field) ->
        raise_invalid(:vector_field, "vector_field is required")

      Keyword.has_key?(opts, :offset) ->
        raise_invalid(
          :offset,
          "search_stream does not support :offset; use :limit alone or switch to search/4"
        )

      true ->
        :ok
    end

    Enum.each(@forbidden_search_opts, fn key ->
      if Keyword.has_key?(opts, key) do
        raise_invalid(key, "#{key} is not supported in search_stream")
      end
    end)

    validate_batch_size!(opts)
    validate_limit!(opts)
  end

  defp validate_batch_size!(opts) do
    case Keyword.get(opts, :batch_size, @default_batch_size) do
      n when is_integer(n) and n > 0 and n <= @max_batch_size -> :ok
      _ -> raise_invalid(:batch_size, "batch_size must be an integer in 1..#{@max_batch_size}")
    end
  end

  defp validate_limit!(opts) do
    case Keyword.get(opts, :limit) do
      nil -> :ok
      n when is_integer(n) and n > 0 -> :ok
      _ -> raise_invalid(:limit, "limit must be a positive integer or nil")
    end
  end

  defp start_search(conn, collection, vector, opts) do
    collection_name = Internal.resolve_collection_name(collection)

    {:ok, channel_fn, rpc_opts} = resolve_channel!(conn, opts)

    {:ok, schema} =
      Internal.resolve_schema(
        conn,
        collection,
        collection_name,
        opts,
        &Milvex.describe_collection/3
      )

    {:ok, field, is_nested} = Internal.find_vector_field(schema, opts[:vector_field])
    {:ok, placeholder_bytes} = Internal.build_ann_placeholder_group([vector], field, is_nested)

    base_request = %SearchRequest{
      db_name: Keyword.get(opts, :db_name, ""),
      collection_name: collection_name,
      partition_names: Keyword.get(opts, :partition_names, []),
      dsl: Keyword.get(opts, :filter, ""),
      dsl_type: :BoolExprV1,
      search_input: {:placeholder_group, placeholder_bytes},
      output_fields: Keyword.get(opts, :output_fields, []),
      nq: 1,
      consistency_level: Keyword.get(opts, :consistency_level, :Bounded),
      expr_template_values: ExprParams.to_proto(opts[:expr_params]),
      highlighter: Internal.build_highlighter(opts[:highlight])
    }

    %{
      channel_fn: channel_fn,
      rpc_opts: rpc_opts,
      base_request: base_request,
      vector_field: opts[:vector_field],
      metric_type: opts[:metric_type],
      user_search_params: opts[:search_params] || %{},
      batch_size: Keyword.get(opts, :batch_size, @default_batch_size),
      total_limit: Keyword.get(opts, :limit) || :infinity,
      consistency_level: Keyword.get(opts, :consistency_level, :Bounded),
      token: nil,
      last_bound: nil,
      session_ts: nil,
      emitted: 0,
      first?: true,
      halted: false
    }
  end

  defp next_search(%{halted: true} = state), do: {:halt, state}

  defp next_search(state) do
    request = build_search_request(state)

    case RPC.call(state.channel_fn, MilvusService.Stub, :search, request, state.rpc_opts) do
      {:ok, %{status: %{code: 0}} = resp} ->
        handle_search_response(resp, state)

      {:ok, resp} ->
        raise RPC.status_to_error(resp.status, "SearchStream")

      {:error, error} ->
        raise error
    end
  end

  defp handle_search_response(resp, state) do
    iter_meta = resp.results && resp.results.search_iterator_v2_results
    parsed = SearchResult.from_proto(resp)
    hits = parsed_first_group(parsed.hits)

    state =
      if state.first? do
        gate_first_response!(hits, iter_meta, resp.session_ts, state.consistency_level)
        %{state | first?: false, session_ts: resp.session_ts}
      else
        state
      end

    {emit, state} = apply_limit(hits, state)
    state = update_cursor(state, iter_meta)

    state =
      cond do
        emit == [] -> %{state | halted: true}
        state.emitted >= total_limit_value(state) -> %{state | halted: true}
        match?(%{token: ""}, iter_meta || %{}) -> %{state | halted: true}
        true -> state
      end

    {emit, state}
  end

  defp gate_first_response!([], _iter_meta, _session_ts, _level), do: :ok

  defp gate_first_response!(_hits, nil, _session_ts, _level) do
    raise Invalid.exception(
            field: :search_iterator_v2_results,
            message:
              "search iterator V2 not supported by this Milvus server. " <>
                "Upgrade to Milvus >= 2.4 or use offset+limit pagination via Milvex.search/4."
          )
  end

  defp gate_first_response!(_hits, _iter_meta, 0, level) when level in [:Strong, :Bounded] do
    raise Invalid.exception(
            field: :session_ts,
            message:
              "server did not emit session_ts; cannot pin MVCC snapshot for consistency level " <>
                "#{inspect(level)}. Upgrade Milvus or switch to a weaker consistency level."
          )
  end

  defp gate_first_response!(_hits, _iter_meta, _session_ts, _level), do: :ok

  defp parsed_first_group([]), do: []
  defp parsed_first_group([first | _]), do: first

  defp apply_limit(hits, %{total_limit: :infinity} = state) do
    {hits, %{state | emitted: state.emitted + length(hits)}}
  end

  defp apply_limit(hits, state) do
    remaining = state.total_limit - state.emitted
    cut = Enum.take(hits, remaining)
    {cut, %{state | emitted: state.emitted + length(cut)}}
  end

  defp total_limit_value(%{total_limit: :infinity}), do: :infinity
  defp total_limit_value(%{total_limit: n}), do: n

  defp update_cursor(state, nil), do: state

  defp update_cursor(state, %{token: token, last_bound: last_bound}) do
    %{state | token: token, last_bound: last_bound}
  end

  defp build_search_request(state) do
    base_params = [
      %KeyValuePair{key: "anns_field", value: state.vector_field},
      %KeyValuePair{key: "topk", value: to_string(state.batch_size)},
      %KeyValuePair{key: "params", value: Jason.encode!(state.user_search_params)},
      %KeyValuePair{key: "iterator", value: "True"},
      %KeyValuePair{key: "search_iter_v2", value: "true"},
      %KeyValuePair{key: "search_iter_batch_size", value: to_string(state.batch_size)}
    ]

    base_params =
      case state.metric_type do
        nil -> base_params
        m -> [%KeyValuePair{key: "metric_type", value: to_string(m)} | base_params]
      end

    base_params =
      case state.token do
        nil ->
          base_params

        token ->
          [
            %KeyValuePair{key: "search_iter_id", value: token},
            %KeyValuePair{
              key: "search_iter_last_bound",
              value: to_string(state.last_bound)
            }
            | base_params
          ]
      end

    request = %{state.base_request | search_params: base_params}

    if state.session_ts && state.session_ts > 0 do
      %{request | guarantee_timestamp: state.session_ts}
    else
      request
    end
  end

  @doc false
  @spec query_stream(GenServer.server(), Milvex.collection_ref(), String.t(), keyword()) ::
          Enumerable.t()
  def query_stream(conn, collection, expr, opts) do
    validate_query_input!(expr, opts)

    Stream.resource(
      fn -> start_query(conn, collection, expr, opts) end,
      &next_query/1,
      fn _state -> :ok end
    )
  end

  defp validate_query_input!(expr, opts) do
    cond do
      not is_binary(expr) ->
        raise_invalid(:expr, "expr must be a non-empty filter string")

      expr == "" ->
        raise_invalid(:expr, "expr must be a non-empty filter string")

      Keyword.has_key?(opts, :offset) ->
        raise_invalid(:offset, "query_stream does not support :offset; use :limit alone")

      true ->
        :ok
    end

    validate_batch_size!(opts)
    validate_limit!(opts)
  end

  defp start_query(conn, collection, expr, opts) do
    collection_name = Internal.resolve_collection_name(collection)

    {:ok, channel_fn, rpc_opts} = resolve_channel!(conn, opts)

    base_request = %QueryRequest{
      db_name: Keyword.get(opts, :db_name, ""),
      collection_name: collection_name,
      expr: expr,
      output_fields: Keyword.get(opts, :output_fields, []),
      partition_names: Keyword.get(opts, :partition_names, []),
      consistency_level: Keyword.get(opts, :consistency_level, :Bounded),
      expr_template_values: ExprParams.to_proto(opts[:expr_params])
    }

    %{
      channel_fn: channel_fn,
      rpc_opts: rpc_opts,
      base_request: base_request,
      original_expr: expr,
      pk_field: nil,
      batch_size: Keyword.get(opts, :batch_size, @default_batch_size),
      total_limit: Keyword.get(opts, :limit) || :infinity,
      consistency_level: Keyword.get(opts, :consistency_level, :Bounded),
      pk_cursor: nil,
      session_ts: nil,
      emitted: 0,
      first?: true,
      halted: false
    }
  end

  defp next_query(%{halted: true} = state), do: {:halt, state}

  defp next_query(state) do
    request = build_query_request(state)

    case RPC.call(state.channel_fn, MilvusService.Stub, :query, request, state.rpc_opts) do
      {:ok, %{status: %{code: 0}} = resp} ->
        handle_query_response(resp, state)

      {:ok, resp} ->
        raise RPC.status_to_error(resp.status, "QueryStream")

      {:error, error} ->
        raise error
    end
  end

  defp handle_query_response(resp, state) do
    parsed = QueryResult.from_proto(resp)
    rows = parsed.rows
    pk_field = parsed.primary_field_name

    state =
      if state.first? do
        gate_query_first_response!(rows, resp.session_ts, state.consistency_level)
        %{state | first?: false, session_ts: resp.session_ts, pk_field: pk_field}
      else
        state
      end

    {emit, state} = apply_limit(rows, state)
    state = update_pk_cursor(state, rows, pk_field)

    state =
      cond do
        emit == [] -> %{state | halted: true}
        state.emitted >= total_limit_value(state) -> %{state | halted: true}
        true -> state
      end

    {emit, state}
  end

  defp gate_query_first_response!([], _session_ts, _level), do: :ok

  defp gate_query_first_response!(_rows, 0, level) when level in [:Strong, :Bounded] do
    raise Invalid.exception(
            field: :session_ts,
            message:
              "server did not emit session_ts; cannot pin MVCC snapshot for consistency level " <>
                "#{inspect(level)}. Upgrade Milvus or switch to a weaker consistency level."
          )
  end

  defp gate_query_first_response!(_rows, _session_ts, _level), do: :ok

  defp update_pk_cursor(state, [], _pk_field), do: state
  defp update_pk_cursor(state, _rows, nil), do: state

  defp update_pk_cursor(state, rows, pk_field) do
    last_pk = rows |> List.last() |> Map.get(pk_field)
    %{state | pk_cursor: last_pk}
  end

  defp build_query_request(state) do
    base_params = [
      %KeyValuePair{key: @query_iter_keys.enable, value: "True"},
      %KeyValuePair{key: @query_iter_keys.limit, value: to_string(state.batch_size)}
    ]

    base_params =
      case state.pk_cursor do
        nil ->
          base_params

        pk ->
          [
            %KeyValuePair{key: @query_iter_keys.last_pk, value: to_string(pk)} | base_params
          ]
      end

    request = %{state.base_request | query_params: base_params, expr: continuation_expr(state)}

    if state.session_ts && state.session_ts > 0 do
      %{request | guarantee_timestamp: state.session_ts}
    else
      request
    end
  end

  defp continuation_expr(%{pk_cursor: nil} = state), do: state.original_expr

  defp continuation_expr(%{pk_cursor: pk, pk_field: pk_field, original_expr: expr})
       when is_binary(pk_field) do
    "(#{expr}) and #{pk_field} > #{format_pk(pk)}"
  end

  defp format_pk(pk) when is_binary(pk), do: ~s("#{pk}")
  defp format_pk(pk), do: to_string(pk)

  defp resolve_channel!(conn, opts) do
    case Connection.get_channel(conn, opts) do
      {:ok, _channel, config} ->
        channel_fn = fn -> Connection.get_channel(conn, opts) end
        {:ok, channel_fn, Config.merge_rpc_opts(config, opts)}

      {:error, error} ->
        raise error
    end
  end

  defp raise_invalid(field, message) do
    raise Invalid.exception(field: field, message: message)
  end
end
