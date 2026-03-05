// ============================================================
// Module: Virtual Network
// Deploys VNet with subnets for AppGW, Backend, and AGC
// ============================================================

@description('Azure region for deployment')
param location string

@description('Resource name prefix')
param prefix string = 'waf-workshop'

var vnetName = '${prefix}-vnet'
var vnetAddressPrefix = '10.0.0.0/16'

var subnets = [
  {
    name: 'snet-appgw'
    addressPrefix: '10.0.1.0/24'
    delegations: []
    serviceEndpoints: []
  }
  {
    name: 'snet-backend'
    addressPrefix: '10.0.2.0/24'
    delegations: [
      {
        name: 'Microsoft.Web.serverFarms'
        properties: {
          serviceName: 'Microsoft.Web/serverFarms'
        }
      }
    ]
    serviceEndpoints: [
      {
        service: 'Microsoft.Web'
      }
    ]
  }
  {
    name: 'snet-agc'
    addressPrefix: '10.0.3.0/24'
    delegations: [
      {
        name: 'Microsoft.ServiceNetworking.trafficControllers'
        properties: {
          serviceName: 'Microsoft.ServiceNetworking/trafficControllers'
        }
      }
    ]
    serviceEndpoints: []
  }
]

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      for subnet in subnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.addressPrefix
          delegations: subnet.delegations
          serviceEndpoints: subnet.serviceEndpoints
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output appgwSubnetId string = vnet.properties.subnets[0].id
output backendSubnetId string = vnet.properties.subnets[1].id
output agcSubnetId string = vnet.properties.subnets[2].id
