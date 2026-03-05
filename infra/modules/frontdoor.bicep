// ============================================================
// Module: Azure Front Door Premium with WAF Policy
// ============================================================

@description('Resource name prefix')
param prefix string = 'waf-workshop'

@description('Backend app FQDN 1')
param backendFqdn1 string

@description('Backend app FQDN 2')
param backendFqdn2 string

var fdName = '${prefix}-fd-${uniqueString(resourceGroup().id)}'
var fdWafPolicyName = '${prefix}-fd-waf-policy'
var endpointName = '${prefix}-endpoint'

// --- Front Door WAF Policy ---
resource fdWafPolicy 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2024-02-01' = {
  name: fdWafPolicyName
  location: 'Global'
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: 'Detection'
      requestBodyCheck: 'Enabled'
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'Microsoft_DefaultRuleSet'
          ruleSetVersion: '2.1'
          ruleSetAction: 'Block'
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '1.1'
        }
      ]
    }
  }
}

// --- Front Door Profile ---
resource frontDoor 'Microsoft.Cdn/profiles@2024-02-01' = {
  name: fdName
  location: 'Global'
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
  properties: {
    originResponseTimeoutSeconds: 60
  }
}

// --- Endpoint ---
resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2024-02-01' = {
  parent: frontDoor
  name: endpointName
  location: 'Global'
  properties: {
    enabledState: 'Enabled'
  }
}

// --- Origin Group ---
resource originGroup 'Microsoft.Cdn/profiles/originGroups@2024-02-01' = {
  parent: frontDoor
  name: 'backend-origin-group'
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 60
    }
  }
}

// --- Origins ---
resource origin1 'Microsoft.Cdn/profiles/originGroups/origins@2024-02-01' = {
  parent: originGroup
  name: 'webapp1-origin'
  properties: {
    hostName: backendFqdn1
    httpPort: 80
    httpsPort: 443
    originHostHeader: backendFqdn1
    priority: 1
    weight: 1000
  }
}

resource origin2 'Microsoft.Cdn/profiles/originGroups/origins@2024-02-01' = {
  parent: originGroup
  name: 'webapp2-origin'
  properties: {
    hostName: backendFqdn2
    httpPort: 80
    httpsPort: 443
    originHostHeader: backendFqdn2
    priority: 1
    weight: 1000
  }
}

// --- Route ---
resource route 'Microsoft.Cdn/profiles/afdEndpoints/routes@2024-02-01' = {
  parent: endpoint
  name: 'default-route'
  properties: {
    originGroup: {
      id: originGroup.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
  }
  dependsOn: [
    origin1
    origin2
  ]
}

// --- Security Policy (WAF association) ---
resource securityPolicy 'Microsoft.Cdn/profiles/securityPolicies@2024-02-01' = {
  parent: frontDoor
  name: 'waf-security-policy'
  properties: {
    parameters: {
      type: 'WebApplicationFirewall'
      wafPolicy: {
        id: fdWafPolicy.id
      }
      associations: [
        {
          domains: [
            {
              id: endpoint.id
            }
          ]
          patternsToMatch: [
            '/*'
          ]
        }
      ]
    }
  }
}

output fdId string = frontDoor.id
output fdName string = frontDoor.name
output fdEndpointHostName string = endpoint.properties.hostName
output fdWafPolicyId string = fdWafPolicy.id
output fdWafPolicyName string = fdWafPolicy.name
