// ============================================================
// Azure WAF Workshop - Main Deployment Template
// Deploys all infrastructure for hands-on labs
// ============================================================

targetScope = 'resourceGroup'

@description('Azure region for deployment')
param location string = resourceGroup().location

@description('Resource name prefix')
param prefix string = 'waf-workshop'

@description('Deploy Sentinel workspace (optional, requires license)')
param deploySentinel bool = false

// --- VNet ---
module vnet 'modules/vnet.bicep' = {
  name: 'deploy-vnet'
  params: {
    location: location
    prefix: prefix
  }
}

// --- Backend Web Apps ---
module webapps 'modules/webapps.bicep' = {
  name: 'deploy-webapps'
  params: {
    location: location
    prefix: prefix
    backendSubnetId: vnet.outputs.backendSubnetId
  }
}

// --- Application Gateway WAF v2 ---
module appgw 'modules/appgw-waf.bicep' = {
  name: 'deploy-appgw'
  params: {
    location: location
    prefix: prefix
    appgwSubnetId: vnet.outputs.appgwSubnetId
    backendFqdn1: webapps.outputs.app1DefaultHostname
    backendFqdn2: webapps.outputs.app2DefaultHostname
  }
}

// --- Front Door Premium ---
module frontdoor 'modules/frontdoor.bicep' = {
  name: 'deploy-frontdoor'
  params: {
    prefix: prefix
    backendFqdn1: webapps.outputs.app1DefaultHostname
    backendFqdn2: webapps.outputs.app2DefaultHostname
  }
}

// --- Application Gateway for Containers ---
module agc 'modules/agc.bicep' = {
  name: 'deploy-agc'
  params: {
    location: location
    prefix: prefix
    agcSubnetId: vnet.outputs.agcSubnetId
  }
}

// --- Log Analytics ---
module logging 'modules/log-analytics.bicep' = {
  name: 'deploy-logging'
  params: {
    location: location
    prefix: prefix
    appgwId: appgw.outputs.appgwId
    frontDoorId: frontdoor.outputs.fdId
  }
}

// --- Sentinel (Optional) ---
module sentinel 'modules/sentinel.bicep' = if (deploySentinel) {
  name: 'deploy-sentinel'
  params: {
    workspaceName: logging.outputs.workspaceName
  }
}

// ============================================================
// Outputs
// ============================================================
output resourceGroupName string = resourceGroup().name
output vnetName string = vnet.outputs.vnetName

output app1Hostname string = webapps.outputs.app1DefaultHostname
output app2Hostname string = webapps.outputs.app2DefaultHostname

output appgwPublicIp string = appgw.outputs.appgwPublicIp
output appgwFqdn string = appgw.outputs.appgwFqdn
output appgwWafPolicyName string = appgw.outputs.wafPolicyName

output frontDoorEndpoint string = frontdoor.outputs.fdEndpointHostName
output frontDoorWafPolicyName string = frontdoor.outputs.fdWafPolicyName

output agcName string = agc.outputs.agcName

output logAnalyticsWorkspace string = logging.outputs.workspaceName
