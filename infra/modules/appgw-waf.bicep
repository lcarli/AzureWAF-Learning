// ============================================================
// Module: Application Gateway WAF v2
// Deploys AppGW with WAF Policy (DRS 2.1, Detection mode)
// ============================================================

@description('Azure region for deployment')
param location string

@description('Resource name prefix')
param prefix string = 'waf-workshop'

@description('Application Gateway subnet ID')
param appgwSubnetId string

@description('Backend app FQDN 1')
param backendFqdn1 string

@description('Backend app FQDN 2')
param backendFqdn2 string

var appgwName = '${prefix}-appgw'
var appgwPipName = '${prefix}-appgw-pip'
var wafPolicyName = '${prefix}-appgw-waf-policy'

// --- WAF Policy ---
resource wafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2024-01-01' = {
  name: wafPolicyName
  location: location
  properties: {
    policySettings: {
      state: 'Enabled'
      mode: 'Detection'
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
      requestBodyInspectLimitInKB: 128
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'Microsoft_DefaultRuleSet'
          ruleSetVersion: '2.1'
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '1.1'
        }
      ]
    }
  }
}

// --- Public IP ---
resource pip 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: appgwPipName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: '${prefix}-appgw-${uniqueString(resourceGroup().id)}'
    }
  }
}

// --- Application Gateway ---
resource appgw 'Microsoft.Network/applicationGateways@2024-01-01' = {
  name: appgwName
  location: location
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: 1
    }
    firewallPolicy: {
      id: wafPolicy.id
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: appgwSubnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          publicIPAddress: {
            id: pip.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'backendPool'
        properties: {
          backendAddresses: [
            {
              fqdn: backendFqdn1
            }
            {
              fqdn: backendFqdn2
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'httpSettings'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 30
        }
      }
    ]
    httpListeners: [
      {
        name: 'httpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appgwName, 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appgwName, 'port_80')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'routingRule1'
        properties: {
          priority: 100
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appgwName, 'httpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appgwName, 'backendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appgwName, 'httpSettings')
          }
        }
      }
    ]
  }
}

output appgwId string = appgw.id
output appgwName string = appgw.name
output appgwPublicIp string = pip.properties.ipAddress
output appgwFqdn string = pip.properties.dnsSettings.fqdn
output wafPolicyId string = wafPolicy.id
output wafPolicyName string = wafPolicy.name
