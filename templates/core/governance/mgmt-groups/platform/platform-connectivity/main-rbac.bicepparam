using './main-rbac.bicep'

param parCorpManagementGroupName = 'corp'
param parConnectivityManagementGroupName = 'connectivity'
param parManagementGroupExcludedPolicyAssignments = ['Enable-DDoS-VNET']
param parEnableTelemetry = false
