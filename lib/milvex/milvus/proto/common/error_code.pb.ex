defmodule Milvex.Milvus.Proto.Common.ErrorCode do
  @moduledoc """
  Deprecated
  """

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :Success, 0
  field :UnexpectedError, 1
  field :ConnectFailed, 2
  field :PermissionDenied, 3
  field :CollectionNotExists, 4
  field :IllegalArgument, 5
  field :IllegalDimension, 7
  field :IllegalIndexType, 8
  field :IllegalCollectionName, 9
  field :IllegalTOPK, 10
  field :IllegalRowRecord, 11
  field :IllegalVectorID, 12
  field :IllegalSearchResult, 13
  field :FileNotFound, 14
  field :MetaFailed, 15
  field :CacheFailed, 16
  field :CannotCreateFolder, 17
  field :CannotCreateFile, 18
  field :CannotDeleteFolder, 19
  field :CannotDeleteFile, 20
  field :BuildIndexError, 21
  field :IllegalNLIST, 22
  field :IllegalMetricType, 23
  field :OutOfMemory, 24
  field :IndexNotExist, 25
  field :EmptyCollection, 26
  field :UpdateImportTaskFailure, 27
  field :CollectionNameNotFound, 28
  field :CreateCredentialFailure, 29
  field :UpdateCredentialFailure, 30
  field :DeleteCredentialFailure, 31
  field :GetCredentialFailure, 32
  field :ListCredUsersFailure, 33
  field :GetUserFailure, 34
  field :CreateRoleFailure, 35
  field :DropRoleFailure, 36
  field :OperateUserRoleFailure, 37
  field :SelectRoleFailure, 38
  field :SelectUserFailure, 39
  field :SelectResourceFailure, 40
  field :OperatePrivilegeFailure, 41
  field :SelectGrantFailure, 42
  field :RefreshPolicyInfoCacheFailure, 43
  field :ListPolicyFailure, 44
  field :NotShardLeader, 45
  field :NoReplicaAvailable, 46
  field :SegmentNotFound, 47
  field :ForceDeny, 48
  field :RateLimit, 49
  field :NodeIDNotMatch, 50
  field :UpsertAutoIDTrue, 51
  field :InsufficientMemoryToLoad, 52
  field :MemoryQuotaExhausted, 53
  field :DiskQuotaExhausted, 54
  field :TimeTickLongDelay, 55
  field :NotReadyServe, 56
  field :NotReadyCoordActivating, 57
  field :CreatePrivilegeGroupFailure, 58
  field :DropPrivilegeGroupFailure, 59
  field :ListPrivilegeGroupsFailure, 60
  field :OperatePrivilegeGroupFailure, 61
  field :SchemaMismatch, 62
  field :DataCoordNA, 100
  field :DDRequestRace, 1000
end
