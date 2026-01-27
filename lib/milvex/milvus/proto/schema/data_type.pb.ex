defmodule Milvex.Milvus.Proto.Schema.DataType do
  @moduledoc """
  *
  @brief Field data type
  """

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :None, 0
  field :Bool, 1
  field :Int8, 2
  field :Int16, 3
  field :Int32, 4
  field :Int64, 5
  field :Float, 10
  field :Double, 11
  field :String, 20
  field :VarChar, 21
  field :Array, 22
  field :JSON, 23
  field :Geometry, 24
  field :Text, 25
  field :Timestamptz, 26
  field :Mol, 27
  field :BinaryVector, 100
  field :FloatVector, 101
  field :Float16Vector, 102
  field :BFloat16Vector, 103
  field :SparseFloatVector, 104
  field :Int8Vector, 105
  field :ArrayOfVector, 106
  field :ArrayOfStruct, 200
  field :Struct, 201
end
