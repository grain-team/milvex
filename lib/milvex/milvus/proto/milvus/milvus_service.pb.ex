defmodule Milvex.Milvus.Proto.Milvus.MilvusService.Service do
  use GRPC.Service, name: "milvus.proto.milvus.MilvusService", protoc_gen_elixir_version: "0.15.0"

  rpc :CreateCollection,
      Milvex.Milvus.Proto.Milvus.CreateCollectionRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :DropCollection,
      Milvex.Milvus.Proto.Milvus.DropCollectionRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :HasCollection,
      Milvex.Milvus.Proto.Milvus.HasCollectionRequest,
      Milvex.Milvus.Proto.Milvus.BoolResponse

  rpc :LoadCollection,
      Milvex.Milvus.Proto.Milvus.LoadCollectionRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :ReleaseCollection,
      Milvex.Milvus.Proto.Milvus.ReleaseCollectionRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :DescribeCollection,
      Milvex.Milvus.Proto.Milvus.DescribeCollectionRequest,
      Milvex.Milvus.Proto.Milvus.DescribeCollectionResponse

  rpc :BatchDescribeCollection,
      Milvex.Milvus.Proto.Milvus.BatchDescribeCollectionRequest,
      Milvex.Milvus.Proto.Milvus.BatchDescribeCollectionResponse

  rpc :GetCollectionStatistics,
      Milvex.Milvus.Proto.Milvus.GetCollectionStatisticsRequest,
      Milvex.Milvus.Proto.Milvus.GetCollectionStatisticsResponse

  rpc :ShowCollections,
      Milvex.Milvus.Proto.Milvus.ShowCollectionsRequest,
      Milvex.Milvus.Proto.Milvus.ShowCollectionsResponse

  rpc :AlterCollection,
      Milvex.Milvus.Proto.Milvus.AlterCollectionRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :AlterCollectionField,
      Milvex.Milvus.Proto.Milvus.AlterCollectionFieldRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :AddCollectionFunction,
      Milvex.Milvus.Proto.Milvus.AddCollectionFunctionRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :AlterCollectionFunction,
      Milvex.Milvus.Proto.Milvus.AlterCollectionFunctionRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :DropCollectionFunction,
      Milvex.Milvus.Proto.Milvus.DropCollectionFunctionRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :TruncateCollection,
      Milvex.Milvus.Proto.Milvus.TruncateCollectionRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :CreatePartition,
      Milvex.Milvus.Proto.Milvus.CreatePartitionRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :DropPartition,
      Milvex.Milvus.Proto.Milvus.DropPartitionRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :HasPartition,
      Milvex.Milvus.Proto.Milvus.HasPartitionRequest,
      Milvex.Milvus.Proto.Milvus.BoolResponse

  rpc :LoadPartitions,
      Milvex.Milvus.Proto.Milvus.LoadPartitionsRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :ReleasePartitions,
      Milvex.Milvus.Proto.Milvus.ReleasePartitionsRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :GetPartitionStatistics,
      Milvex.Milvus.Proto.Milvus.GetPartitionStatisticsRequest,
      Milvex.Milvus.Proto.Milvus.GetPartitionStatisticsResponse

  rpc :ShowPartitions,
      Milvex.Milvus.Proto.Milvus.ShowPartitionsRequest,
      Milvex.Milvus.Proto.Milvus.ShowPartitionsResponse

  rpc :GetLoadingProgress,
      Milvex.Milvus.Proto.Milvus.GetLoadingProgressRequest,
      Milvex.Milvus.Proto.Milvus.GetLoadingProgressResponse

  rpc :GetLoadState,
      Milvex.Milvus.Proto.Milvus.GetLoadStateRequest,
      Milvex.Milvus.Proto.Milvus.GetLoadStateResponse

  rpc :CreateAlias,
      Milvex.Milvus.Proto.Milvus.CreateAliasRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :DropAlias, Milvex.Milvus.Proto.Milvus.DropAliasRequest, Milvex.Milvus.Proto.Common.Status

  rpc :AlterAlias, Milvex.Milvus.Proto.Milvus.AlterAliasRequest, Milvex.Milvus.Proto.Common.Status

  rpc :DescribeAlias,
      Milvex.Milvus.Proto.Milvus.DescribeAliasRequest,
      Milvex.Milvus.Proto.Milvus.DescribeAliasResponse

  rpc :ListAliases,
      Milvex.Milvus.Proto.Milvus.ListAliasesRequest,
      Milvex.Milvus.Proto.Milvus.ListAliasesResponse

  rpc :CreateIndex,
      Milvex.Milvus.Proto.Milvus.CreateIndexRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :AlterIndex, Milvex.Milvus.Proto.Milvus.AlterIndexRequest, Milvex.Milvus.Proto.Common.Status

  rpc :DescribeIndex,
      Milvex.Milvus.Proto.Milvus.DescribeIndexRequest,
      Milvex.Milvus.Proto.Milvus.DescribeIndexResponse

  rpc :GetIndexStatistics,
      Milvex.Milvus.Proto.Milvus.GetIndexStatisticsRequest,
      Milvex.Milvus.Proto.Milvus.GetIndexStatisticsResponse

  rpc :GetIndexState,
      Milvex.Milvus.Proto.Milvus.GetIndexStateRequest,
      Milvex.Milvus.Proto.Milvus.GetIndexStateResponse

  rpc :GetIndexBuildProgress,
      Milvex.Milvus.Proto.Milvus.GetIndexBuildProgressRequest,
      Milvex.Milvus.Proto.Milvus.GetIndexBuildProgressResponse

  rpc :DropIndex, Milvex.Milvus.Proto.Milvus.DropIndexRequest, Milvex.Milvus.Proto.Common.Status

  rpc :Insert, Milvex.Milvus.Proto.Milvus.InsertRequest, Milvex.Milvus.Proto.Milvus.MutationResult

  rpc :Delete, Milvex.Milvus.Proto.Milvus.DeleteRequest, Milvex.Milvus.Proto.Milvus.MutationResult

  rpc :Upsert, Milvex.Milvus.Proto.Milvus.UpsertRequest, Milvex.Milvus.Proto.Milvus.MutationResult

  rpc :Search, Milvex.Milvus.Proto.Milvus.SearchRequest, Milvex.Milvus.Proto.Milvus.SearchResults

  rpc :HybridSearch,
      Milvex.Milvus.Proto.Milvus.HybridSearchRequest,
      Milvex.Milvus.Proto.Milvus.SearchResults

  rpc :Flush, Milvex.Milvus.Proto.Milvus.FlushRequest, Milvex.Milvus.Proto.Milvus.FlushResponse

  rpc :Query, Milvex.Milvus.Proto.Milvus.QueryRequest, Milvex.Milvus.Proto.Milvus.QueryResults

  rpc :CalcDistance,
      Milvex.Milvus.Proto.Milvus.CalcDistanceRequest,
      Milvex.Milvus.Proto.Milvus.CalcDistanceResults

  rpc :FlushAll,
      Milvex.Milvus.Proto.Milvus.FlushAllRequest,
      Milvex.Milvus.Proto.Milvus.FlushAllResponse

  rpc :AddCollectionField,
      Milvex.Milvus.Proto.Milvus.AddCollectionFieldRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :GetFlushState,
      Milvex.Milvus.Proto.Milvus.GetFlushStateRequest,
      Milvex.Milvus.Proto.Milvus.GetFlushStateResponse

  rpc :GetFlushAllState,
      Milvex.Milvus.Proto.Milvus.GetFlushAllStateRequest,
      Milvex.Milvus.Proto.Milvus.GetFlushAllStateResponse

  rpc :GetPersistentSegmentInfo,
      Milvex.Milvus.Proto.Milvus.GetPersistentSegmentInfoRequest,
      Milvex.Milvus.Proto.Milvus.GetPersistentSegmentInfoResponse

  rpc :GetQuerySegmentInfo,
      Milvex.Milvus.Proto.Milvus.GetQuerySegmentInfoRequest,
      Milvex.Milvus.Proto.Milvus.GetQuerySegmentInfoResponse

  rpc :GetReplicas,
      Milvex.Milvus.Proto.Milvus.GetReplicasRequest,
      Milvex.Milvus.Proto.Milvus.GetReplicasResponse

  rpc :Dummy, Milvex.Milvus.Proto.Milvus.DummyRequest, Milvex.Milvus.Proto.Milvus.DummyResponse

  rpc :RegisterLink,
      Milvex.Milvus.Proto.Milvus.RegisterLinkRequest,
      Milvex.Milvus.Proto.Milvus.RegisterLinkResponse

  rpc :GetMetrics,
      Milvex.Milvus.Proto.Milvus.GetMetricsRequest,
      Milvex.Milvus.Proto.Milvus.GetMetricsResponse

  rpc :GetComponentStates,
      Milvex.Milvus.Proto.Milvus.GetComponentStatesRequest,
      Milvex.Milvus.Proto.Milvus.ComponentStates

  rpc :LoadBalance,
      Milvex.Milvus.Proto.Milvus.LoadBalanceRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :GetCompactionState,
      Milvex.Milvus.Proto.Milvus.GetCompactionStateRequest,
      Milvex.Milvus.Proto.Milvus.GetCompactionStateResponse

  rpc :ManualCompaction,
      Milvex.Milvus.Proto.Milvus.ManualCompactionRequest,
      Milvex.Milvus.Proto.Milvus.ManualCompactionResponse

  rpc :GetCompactionStateWithPlans,
      Milvex.Milvus.Proto.Milvus.GetCompactionPlansRequest,
      Milvex.Milvus.Proto.Milvus.GetCompactionPlansResponse

  rpc :Import, Milvex.Milvus.Proto.Milvus.ImportRequest, Milvex.Milvus.Proto.Milvus.ImportResponse

  rpc :GetImportState,
      Milvex.Milvus.Proto.Milvus.GetImportStateRequest,
      Milvex.Milvus.Proto.Milvus.GetImportStateResponse

  rpc :ListImportTasks,
      Milvex.Milvus.Proto.Milvus.ListImportTasksRequest,
      Milvex.Milvus.Proto.Milvus.ListImportTasksResponse

  rpc :CreateCredential,
      Milvex.Milvus.Proto.Milvus.CreateCredentialRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :UpdateCredential,
      Milvex.Milvus.Proto.Milvus.UpdateCredentialRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :DeleteCredential,
      Milvex.Milvus.Proto.Milvus.DeleteCredentialRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :ListCredUsers,
      Milvex.Milvus.Proto.Milvus.ListCredUsersRequest,
      Milvex.Milvus.Proto.Milvus.ListCredUsersResponse

  rpc :CreateRole, Milvex.Milvus.Proto.Milvus.CreateRoleRequest, Milvex.Milvus.Proto.Common.Status

  rpc :DropRole, Milvex.Milvus.Proto.Milvus.DropRoleRequest, Milvex.Milvus.Proto.Common.Status

  rpc :OperateUserRole,
      Milvex.Milvus.Proto.Milvus.OperateUserRoleRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :SelectRole,
      Milvex.Milvus.Proto.Milvus.SelectRoleRequest,
      Milvex.Milvus.Proto.Milvus.SelectRoleResponse

  rpc :SelectUser,
      Milvex.Milvus.Proto.Milvus.SelectUserRequest,
      Milvex.Milvus.Proto.Milvus.SelectUserResponse

  rpc :OperatePrivilege,
      Milvex.Milvus.Proto.Milvus.OperatePrivilegeRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :OperatePrivilegeV2,
      Milvex.Milvus.Proto.Milvus.OperatePrivilegeV2Request,
      Milvex.Milvus.Proto.Common.Status

  rpc :SelectGrant,
      Milvex.Milvus.Proto.Milvus.SelectGrantRequest,
      Milvex.Milvus.Proto.Milvus.SelectGrantResponse

  rpc :GetVersion,
      Milvex.Milvus.Proto.Milvus.GetVersionRequest,
      Milvex.Milvus.Proto.Milvus.GetVersionResponse

  rpc :CheckHealth,
      Milvex.Milvus.Proto.Milvus.CheckHealthRequest,
      Milvex.Milvus.Proto.Milvus.CheckHealthResponse

  rpc :CreateResourceGroup,
      Milvex.Milvus.Proto.Milvus.CreateResourceGroupRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :DropResourceGroup,
      Milvex.Milvus.Proto.Milvus.DropResourceGroupRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :UpdateResourceGroups,
      Milvex.Milvus.Proto.Milvus.UpdateResourceGroupsRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :TransferNode,
      Milvex.Milvus.Proto.Milvus.TransferNodeRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :TransferReplica,
      Milvex.Milvus.Proto.Milvus.TransferReplicaRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :ListResourceGroups,
      Milvex.Milvus.Proto.Milvus.ListResourceGroupsRequest,
      Milvex.Milvus.Proto.Milvus.ListResourceGroupsResponse

  rpc :DescribeResourceGroup,
      Milvex.Milvus.Proto.Milvus.DescribeResourceGroupRequest,
      Milvex.Milvus.Proto.Milvus.DescribeResourceGroupResponse

  rpc :RenameCollection,
      Milvex.Milvus.Proto.Milvus.RenameCollectionRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :ListIndexedSegment,
      Milvex.Milvus.Proto.Feder.ListIndexedSegmentRequest,
      Milvex.Milvus.Proto.Feder.ListIndexedSegmentResponse

  rpc :DescribeSegmentIndexData,
      Milvex.Milvus.Proto.Feder.DescribeSegmentIndexDataRequest,
      Milvex.Milvus.Proto.Feder.DescribeSegmentIndexDataResponse

  rpc :Connect,
      Milvex.Milvus.Proto.Milvus.ConnectRequest,
      Milvex.Milvus.Proto.Milvus.ConnectResponse

  rpc :AllocTimestamp,
      Milvex.Milvus.Proto.Milvus.AllocTimestampRequest,
      Milvex.Milvus.Proto.Milvus.AllocTimestampResponse

  rpc :CreateDatabase,
      Milvex.Milvus.Proto.Milvus.CreateDatabaseRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :DropDatabase,
      Milvex.Milvus.Proto.Milvus.DropDatabaseRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :ListDatabases,
      Milvex.Milvus.Proto.Milvus.ListDatabasesRequest,
      Milvex.Milvus.Proto.Milvus.ListDatabasesResponse

  rpc :AlterDatabase,
      Milvex.Milvus.Proto.Milvus.AlterDatabaseRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :DescribeDatabase,
      Milvex.Milvus.Proto.Milvus.DescribeDatabaseRequest,
      Milvex.Milvus.Proto.Milvus.DescribeDatabaseResponse

  rpc :ReplicateMessage,
      Milvex.Milvus.Proto.Milvus.ReplicateMessageRequest,
      Milvex.Milvus.Proto.Milvus.ReplicateMessageResponse

  rpc :BackupRBAC,
      Milvex.Milvus.Proto.Milvus.BackupRBACMetaRequest,
      Milvex.Milvus.Proto.Milvus.BackupRBACMetaResponse

  rpc :RestoreRBAC,
      Milvex.Milvus.Proto.Milvus.RestoreRBACMetaRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :CreatePrivilegeGroup,
      Milvex.Milvus.Proto.Milvus.CreatePrivilegeGroupRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :DropPrivilegeGroup,
      Milvex.Milvus.Proto.Milvus.DropPrivilegeGroupRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :ListPrivilegeGroups,
      Milvex.Milvus.Proto.Milvus.ListPrivilegeGroupsRequest,
      Milvex.Milvus.Proto.Milvus.ListPrivilegeGroupsResponse

  rpc :OperatePrivilegeGroup,
      Milvex.Milvus.Proto.Milvus.OperatePrivilegeGroupRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :RunAnalyzer,
      Milvex.Milvus.Proto.Milvus.RunAnalyzerRequest,
      Milvex.Milvus.Proto.Milvus.RunAnalyzerResponse

  rpc :AddFileResource,
      Milvex.Milvus.Proto.Milvus.AddFileResourceRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :RemoveFileResource,
      Milvex.Milvus.Proto.Milvus.RemoveFileResourceRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :ListFileResources,
      Milvex.Milvus.Proto.Milvus.ListFileResourcesRequest,
      Milvex.Milvus.Proto.Milvus.ListFileResourcesResponse

  rpc :AddUserTags,
      Milvex.Milvus.Proto.Milvus.AddUserTagsRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :DeleteUserTags,
      Milvex.Milvus.Proto.Milvus.DeleteUserTagsRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :GetUserTags,
      Milvex.Milvus.Proto.Milvus.GetUserTagsRequest,
      Milvex.Milvus.Proto.Milvus.GetUserTagsResponse

  rpc :ListUsersWithTag,
      Milvex.Milvus.Proto.Milvus.ListUsersWithTagRequest,
      Milvex.Milvus.Proto.Milvus.ListUsersWithTagResponse

  rpc :CreateRowPolicy,
      Milvex.Milvus.Proto.Milvus.CreateRowPolicyRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :DropRowPolicy,
      Milvex.Milvus.Proto.Milvus.DropRowPolicyRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :ListRowPolicies,
      Milvex.Milvus.Proto.Milvus.ListRowPoliciesRequest,
      Milvex.Milvus.Proto.Milvus.ListRowPoliciesResponse

  rpc :UpdateReplicateConfiguration,
      Milvex.Milvus.Proto.Milvus.UpdateReplicateConfigurationRequest,
      Milvex.Milvus.Proto.Common.Status

  rpc :GetReplicateInfo,
      Milvex.Milvus.Proto.Milvus.GetReplicateInfoRequest,
      Milvex.Milvus.Proto.Milvus.GetReplicateInfoResponse

  rpc :CreateReplicateStream,
      stream(Milvex.Milvus.Proto.Milvus.ReplicateRequest),
      stream(Milvex.Milvus.Proto.Milvus.ReplicateResponse)

  rpc :ComputePhraseMatchSlop,
      Milvex.Milvus.Proto.Milvus.ComputePhraseMatchSlopRequest,
      Milvex.Milvus.Proto.Milvus.ComputePhraseMatchSlopResponse
end

defmodule Milvex.Milvus.Proto.Milvus.MilvusService.Stub do
  use GRPC.Stub, service: Milvex.Milvus.Proto.Milvus.MilvusService.Service
end
