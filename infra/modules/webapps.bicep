// ============================================================
// Module: Backend Web Apps
// Deploys App Service Plan + 2 Web Apps for WAF testing
// ============================================================

@description('Azure region for deployment')
param location string

@description('Resource name prefix')
param prefix string = 'waf-workshop'

@description('Backend subnet ID for VNet integration')
param backendSubnetId string

var appServicePlanName = '${prefix}-asp'
var app1Name = '${prefix}-web1-${uniqueString(resourceGroup().id)}'
var app2Name = '${prefix}-web2-${uniqueString(resourceGroup().id)}'

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource webApp1 'Microsoft.Web/sites@2023-12-01' = {
  name: app1Name
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    virtualNetworkSubnetId: backendSubnetId
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      appSettings: [
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~20'
        }
        {
          name: 'SERVER_NAME'
          value: 'WebApp-1'
        }
      ]
    }
    httpsOnly: true
  }
}

resource webApp2 'Microsoft.Web/sites@2023-12-01' = {
  name: app2Name
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    virtualNetworkSubnetId: backendSubnetId
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      appSettings: [
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~20'
        }
        {
          name: 'SERVER_NAME'
          value: 'WebApp-2'
        }
      ]
    }
    httpsOnly: true
  }
}

output app1Name string = webApp1.name
output app2Name string = webApp2.name
output app1DefaultHostname string = webApp1.properties.defaultHostName
output app2DefaultHostname string = webApp2.properties.defaultHostName
output app1Id string = webApp1.id
output app2Id string = webApp2.id
