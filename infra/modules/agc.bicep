// ============================================================
// Module: Application Gateway for Containers (AGC)
// Deploys ALB Controller infrastructure for WAF lab
// ============================================================

@description('Azure region for deployment')
param location string

@description('Resource name prefix')
param prefix string = 'waf-workshop'

@description('AGC subnet ID')
param agcSubnetId string

var agcName = '${prefix}-agc'
var agcWafPolicyName = '${prefix}-agc-waf-policy'

// --- AGC WAF Policy ---
resource agcWafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2024-01-01' = {
  name: agcWafPolicyName
  location: location
  properties: {
    policySettings: {
      state: 'Enabled'
      mode: 'Prevention'
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'Microsoft_DefaultRuleSet'
          ruleSetVersion: '2.1'
        }
      ]
    }
  }
}

// --- Application Gateway for Containers ---
resource agc 'Microsoft.ServiceNetworking/trafficControllers@2024-05-01-preview' = {
  name: agcName
  location: location
  properties: {}
}

// --- AGC Association (subnet) ---
resource agcAssociation 'Microsoft.ServiceNetworking/trafficControllers/associations@2024-05-01-preview' = {
  parent: agc
  name: '${agcName}-association'
  location: location
  properties: {
    associationType: 'subnets'
    subnet: {
      id: agcSubnetId
    }
  }
}

// --- AGC Frontend ---
resource agcFrontend 'Microsoft.ServiceNetworking/trafficControllers/frontends@2024-05-01-preview' = {
  parent: agc
  name: '${agcName}-frontend'
  location: location
  properties: {}
}

output agcId string = agc.id
output agcName string = agc.name
output agcFrontendFqdn string = agcFrontend.properties.fqdn
output agcWafPolicyId string = agcWafPolicy.id
