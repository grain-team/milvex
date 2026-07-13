[
  # GRPC.Stub.connect/2 has an inferred success typing of `{:error, _}` only:
  # dialyzer cannot resolve the dynamic load-balancer dispatch in
  # GRPC.Client.Connection.pick_channel/2, so it treats the `{:ok, channel}`
  # branch of establish_connection/1 (and everything downstream of it) as dead
  # code.
  {"lib/milvex/connection.ex", :pattern_match, {145, 7}},
  {"lib/milvex/connection.ex", :pattern_match, {168, 7}},
  {"lib/milvex/connection.ex", :pattern_match, {281, 7}},
  {"lib/milvex/connection.ex", :pattern_match, {322, 13}},
  {"lib/milvex/connection.ex", :unused_fun, {337, 8}}
]
