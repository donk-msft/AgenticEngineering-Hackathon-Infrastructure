metadata description = 'Compute tier for the Contoso Ticketing workload: Linux App Service with a user-assigned identity and regional VNet integration, built from Azure Verified Modules.'

@description('Workload name used in CAF resource names.')
param workload string

@description('Environment short name.')
param environment string

@description('Azure region.')
param location string

@description('Tags applied to all resources.')
param tags object

@description('Delegated subnet used for regional VNet integration.')
param appSubnetId string

@description('Application Insights connection string.')
param applicationInsightsConnectionString string

@description('Passwordless SQL connection string.')
param sqlConnectionString string

@description('Resource id of the user-assigned managed identity attached to the web app.')
param appIdentityResourceId string

@description('Principal id of the user-assigned managed identity attached to the web app.')
param appIdentityPrincipalId string

@description('Client id of the user-assigned managed identity attached to the web app.')
param appIdentityClientId string

var suffix = '${workload}-${environment}-${location}'

module appServicePlan 'br/public:avm/res/web/serverfarm:0.7.0' = {
  name: 'asp-${suffix}'
  params: {
    name: 'asp-${suffix}'
    location: location
    tags: tags
    skuName: 'P0v3'
    skuCapacity: 1
    kind: 'linux'
    zoneRedundant: false
  }
}

module webApp 'br/public:avm/res/web/site:0.24.0' = {
  name: 'app-${suffix}'
  params: {
    name: 'app-${suffix}'
    location: location
    tags: tags
    kind: 'app,linux'
    serverFarmResourceId: appServicePlan.outputs.resourceId
    managedIdentities: {
      systemAssigned: false
      userAssignedResourceIds: [
        appIdentityResourceId
      ]
    }
    httpsOnly: true
    virtualNetworkSubnetResourceId: appSubnetId
    outboundVnetRouting: {
      allTraffic: true
    }
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|8.0'
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      http20Enabled: true
      alwaysOn: true
      healthCheckPath: '/healthz'
    }
    configs: [
      {
        name: 'appsettings'
        properties: {
          APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsightsConnectionString
          ConnectionStrings__Default: sqlConnectionString
          AZURE_CLIENT_ID: appIdentityClientId
          DOTNET_SYSTEM_GLOBALIZATION_INVARIANT: '0'
        }
      }
    ]
  }
}

output webAppName string = webApp.outputs.name
output defaultHostName string = webApp.outputs.defaultHostname
output principalId string = appIdentityPrincipalId
output clientId string = appIdentityClientId
