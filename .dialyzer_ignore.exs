[
  # GRPC.Stub.connect/2 has an inferred success typing of `{:error, _}` only:
  # dialyzer cannot resolve the dynamic load-balancer dispatch in
  # GRPC.Client.Connection.pick_channel/2, so it treats the `{:ok, channel}`
  # branch of establish_connection/1 (and everything downstream of it) as dead
  # code.
  {"lib/milvex/connection.ex", :pattern_match, {211, 7}},
  {"lib/milvex/connection.ex", :pattern_match, {234, 7}},
  {"lib/milvex/connection.ex", :pattern_match, {376, 7}},
  {"lib/milvex/connection.ex", :pattern_match, {417, 13}},
  {"lib/milvex/connection.ex", :unused_fun, {432, 8}}
]
