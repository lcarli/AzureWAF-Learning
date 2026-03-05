// ============================================================
// Module: Microsoft Sentinel (Optional)
// Deploys Sentinel on top of Log Analytics workspace
// ============================================================

@description('Log Analytics workspace name')
param workspaceName string

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: workspaceName
}

resource sentinel 'Microsoft.SecurityInsights/onboardingStates@2024-03-01' = {
  name: 'default'
  scope: workspace
  properties: {}
}

output sentinelEnabled bool = true
