metadata description = 'Network foundation for the Contoso Ticketing workload: VNet, delegated app subnet, private-endpoint subnet and least-privilege NSGs, built from Azure Verified Modules.'

@description('Workload name used in CAF resource names.')
param workload string

@description('Environment short name.')
param environment string

@description('Azure region.')
param location string

@description('Tags applied to all resources.')
param tags object

@description('Log Analytics workspace used for NSG flow diagnostics.')
param logAnalyticsWorkspaceId string

@description('Address space of the virtual network.')
param addressPrefix string

@description('Address prefix of the delegated App Service subnet.')
param appSubnetPrefix string

@description('Address prefix of the private endpoint subnet.')
param privateEndpointSubnetPrefix string

@description('Address prefix of the deployment script subnet (delegated to Microsoft.ContainerInstance/containerGroups).')
param deployScriptSubnetPrefix string

var suffix = '${workload}-${environment}-${location}'

module appNsg 'br/public:avm/res/network/network-security-group:0.5.3' = {
  name: 'nsg-app-${suffix}'
  params: {
    name: 'nsg-app-${environment}-${location}'
    location: location
    tags: tags
    diagnosticSettings: [
      {
        name: 'diag-to-law'
        workspaceResourceId: logAnalyticsWorkspaceId
      }
    ]
    securityRules: [
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

module privateEndpointNsg 'br/public:avm/res/network/network-security-group:0.5.3' = {
  name: 'nsg-pep-${suffix}'
  params: {
    name: 'nsg-pep-${environment}-${location}'
    location: location
    tags: tags
    diagnosticSettings: [
      {
        name: 'diag-to-law'
        workspaceResourceId: logAnalyticsWorkspaceId
      }
    ]
    securityRules: [
      {
        name: 'AllowSqlFromAppSubnet'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: appSubnetPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: privateEndpointSubnetPrefix
          destinationPortRange: '1433'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

module deployScriptNsg 'br/public:avm/res/network/network-security-group:0.5.3' = {
  name: 'nsg-deployscript-${suffix}'
  params: {
    name: 'nsg-deployscript-${environment}-${location}'
    location: location
    tags: tags
    diagnosticSettings: [
      {
        name: 'diag-to-law'
        workspaceResourceId: logAnalyticsWorkspaceId
      }
    ]
    securityRules: [
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.10.0' = {
  name: 'vnet-${suffix}'
  params: {
    name: 'vnet-${suffix}'
    location: location
    tags: tags
    addressPrefixes: [
      addressPrefix
    ]
    subnets: [
      {
        name: 'snet-app'
        addressPrefix: appSubnetPrefix
        networkSecurityGroupResourceId: appNsg.outputs.resourceId
        delegation: 'Microsoft.Web/serverFarms'
      }
      {
        name: 'snet-privateendpoints'
        addressPrefix: privateEndpointSubnetPrefix
        networkSecurityGroupResourceId: privateEndpointNsg.outputs.resourceId
      }
      {
        name: 'snet-deployscript'
        addressPrefix: deployScriptSubnetPrefix
        networkSecurityGroupResourceId: deployScriptNsg.outputs.resourceId
        delegation: 'Microsoft.ContainerInstance/containerGroups'
        serviceEndpoints: [
          'Microsoft.Storage'
        ]
      }
    ]
  }
}

@description('Resource id of the workload virtual network.')
output virtualNetworkId string = virtualNetwork.outputs.resourceId

@description('Resource id of the delegated App Service subnet.')
output appSubnetId string = virtualNetwork.outputs.subnetResourceIds[0]

@description('Resource id of the SQL private endpoint subnet.')
output privateEndpointSubnetId string = virtualNetwork.outputs.subnetResourceIds[1]

@description('Resource id of the delegated deployment script subnet.')
output deployScriptSubnetId string = virtualNetwork.outputs.subnetResourceIds[2]
