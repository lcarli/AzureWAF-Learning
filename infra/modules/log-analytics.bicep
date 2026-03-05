// ============================================================
// Module: Log Analytics Workspace
// Deploys workspace + diagnostic settings for WAF logging
// ============================================================

@description('Azure region for deployment')
param location string

@description('Resource name prefix')
param prefix string = 'waf-workshop'

@description('Application Gateway resource ID')
param appgwId string

@description('Front Door profile resource ID')
param frontDoorId string

var workspaceName = '${prefix}-law'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// --- Diagnostic Settings: Application Gateway ---
resource appgwDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'appgw-waf-diag'
  scope: resourceId('Microsoft.Network/applicationGateways', last(split(appgwId, '/')))
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'ApplicationGatewayAccessLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayFirewallLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayPerformanceLog'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// --- Diagnostic Settings: Front Door ---
resource fdDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'fd-waf-diag'
  scope: resourceId('Microsoft.Cdn/profiles', last(split(frontDoorId, '/')))
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'FrontDoorAccessLog'
        enabled: true
      }
      {
        category: 'FrontDoorWebApplicationFirewallLog'
        enabled: true
      }
      {
        category: 'FrontDoorHealthProbeLog'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output workspaceId string = logAnalytics.id
output workspaceName string = logAnalytics.name
