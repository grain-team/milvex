# Pagination and Streaming

Milvex exposes two pagination shapes. Choose explicitly based on your use case.

## Shallow paging — `:offset` + `:limit`

Use for paged UI scrolling (page-1, page-2, page-3). Available on
`Milvex.search/4`, `Milvex.hybrid_search/5`, and `Milvex.query/4`. Bounded by
the Milvus server-side hard cap: **`offset + limit <= 16384`** per request.

    {:ok, page} =
      Milvex.search(conn, "movies", [embedding],
        vector_field: "embedding",
        top_k: 20,
        offset: 40
      )

    {:ok, page} =
      Milvex.query(conn, "movies", "year > 2000",
        output_fields: ["id", "title"],
        limit: 50,
        offset: 100
      )

Going over the cap returns `{:error, %Milvex.Errors.Invalid{}}` with a clear
message — milvex enforces this client-side, before any RPC round-trip.

## Deep streaming — `search_stream/4`, `query_stream/4`

Use for full-collection scans, batch processing, ML pipelines. Backed by
Milvus's server-side iterator (no offset, no cap, MVCC-pinned snapshot via
`session_ts`).

    Milvex.search_stream(conn, "movies", embedding,
      vector_field: "embedding",
      filter: "year > 2000",
      batch_size: 1_000
    )
    |> Stream.take(10_000)
    |> Enum.to_list()

    Milvex.query_stream(conn, "movies", "year > 2000",
      output_fields: ["id", "title", "year"],
      batch_size: 1_000
    )
    |> Stream.filter(&(&1["year"] > 2010))
    |> Enum.count()

### Constraints

Iterator mode supports a **single vector** only. Multi-vector or named-query
input raises `Milvex.Errors.Invalid`. Use `search/4` with `:offset`/`:top_k`
for those cases.

Requires Milvus >= 2.4. Older servers raise on the first batch with a clear
upgrade hint.

### Errors

Errors raise from inside the stream — same convention as `File.stream!/1`,
`IO.stream/2`, and `Postgrex` cursors. Wrap `Enum.to_list/1` or
`Stream.run/1` in a `try` if you want to recover.

### Multiple passes over the same data

`Stream.cycle/1`, `Stream.zip/2`, or running the same stream value twice
through `Enum.to_list/1` issues independent RPC sequences with **different**
`session_ts` pins — and roughly doubles the network traffic. If you need
multiple passes over a single MVCC snapshot, materialize once with
`Enum.to_list/1` and then re-iterate the resulting list.

    rows =
      Milvex.query_stream(conn, "movies", "year > 2000", batch_size: 1_000)
      |> Enum.to_list()

    by_year = Enum.group_by(rows, & &1["year"])
    titles = Enum.map(rows, & &1["title"])

## Why no `hybrid_search_stream`

Milvus's server-side iterator does not support sub-requests with reranking.
There is no `hybrid_search_stream/5` and no plan to add one. For deep
pagination on hybrid search, narrow the query with stricter filters or batch
the rerank yourself by combining results from multiple `search_stream/4`
runs.
