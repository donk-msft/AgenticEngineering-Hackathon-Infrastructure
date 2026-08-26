targetScope = 'subscription'

metadata description = '''
Shared hackathon baseline: the "Contoso Ticketing" workload.

Every track (beginner, intermediate, expert) deploys this same architecture, so a
team that finishes the beginner or intermediate track can roll straight into the
expert track without redesigning the workload.
'''

@description('Workload name used in CAF resource names, e.g. rg-<workload>-<env>-<region>.')
@minLength(3)
@maxLength(13)
param workload string

@description('Environment short name.')
@allowed([
  'dev'
  'tst'
  'prd'
])
param environment string

@description('Azure region for all resources. Use a region where the Azure SRE Agent is available if you plan to do the expert track.')
param location string

@description('Owner tag value (team or e-mail address).')
param owner string

@description('Cost centre tag value.')
param costCenter string

@description('Address space of the workload virtual network.')
param vnetAddressPrefix string

@description('Address prefix of the delegated App Service subnet.')
param appSubnetPrefix string

@description('Address prefix of the SQL private endpoint subnet.')
param privateEndpointSubnetPrefix string

@description('Address prefix of the private deployment script subnet.')
param deployScriptSubnetPrefix string

var regionToken = location
var resourceGroupName = 'rg-${workload}-${environment}-${regionToken}'

var tags = {
  environment: environment
  workload: workload
  owner: owner
  costCenter: costCenter
  hackathon: 'agentic-engineering-infrastructure'
}

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module monitoring 'modules/monitoring.bicep' = {
  scope: rg
  name: 'monitoring'
  params: {
    workload: workload
    environment: environment
    location: location
    tags: tags
  }
}

module networking 'modules/networking.bicep' = {
  scope: rg
  name: 'networking'
  params: {
    workload: workload
    environment: environment
    location: location
    tags: tags
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    addressPrefix: vnetAddressPrefix
    appSubnetPrefix: appSubnetPrefix
    privateEndpointSubnetPrefix: privateEndpointSubnetPrefix
    deployScriptSubnetPrefix: deployScriptSubnetPrefix
  }
}

module identityBootstrap 'modules/identity-bootstrap.bicep' = {
  scope: rg
  name: 'identity-bootstrap'
  params: {
    workload: workload
    environment: environment
    location: location
    tags: tags
  }
}

module database 'modules/database.bicep' = {
  scope: rg
  name: 'database'
  params: {
    workload: workload
    environment: environment
    location: location
    tags: tags
    privateEndpointSubnetId: networking.outputs.privateEndpointSubnetId
    virtualNetworkId: networking.outputs.virtualNetworkId
    sqlAdminObjectId: identityBootstrap.outputs.principalId
    sqlAdminLogin: identityBootstrap.outputs.name
  }
}

module webapp 'modules/webapp.bicep' = {
  scope: rg
  name: 'webapp'
  params: {
    workload: workload
    environment: environment
    location: location
    tags: tags
    appSubnetId: networking.outputs.appSubnetId
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    sqlConnectionString: database.outputs.connectionString
  }
}

module databaseBootstrap 'modules/database-bootstrap.bicep' = {
  scope: rg
  name: 'database-bootstrap'
  params: {
    workload: workload
    environment: environment
    location: location
    tags: tags
    deployScriptSubnetId: networking.outputs.deployScriptSubnetId
    managedIdentityResourceId: identityBootstrap.outputs.resourceId
    managedIdentityPrincipalId: identityBootstrap.outputs.principalId
    managedIdentityClientId: identityBootstrap.outputs.clientId
    sqlServerName: database.outputs.sqlServerName
    databaseName: database.outputs.databaseName
    webAppName: webapp.outputs.webAppName
    webAppPrincipalId: webapp.outputs.principalId
  }
}

module alerts 'modules/alerts.bicep' = {
  scope: rg
  name: 'alerts'
  params: {
    workload: workload
    environment: environment
    location: location
    tags: tags
    webAppName: webapp.outputs.webAppName
    webAppHostName: webapp.outputs.defaultHostName
    sqlServerName: database.outputs.sqlServerName
    databaseName: database.outputs.databaseName
    applicationInsightsName: monitoring.outputs.applicationInsightsName
  }
}

@description('Name of the workload resource group.')
output resourceGroupName string = rg.name

@description('Name of the deployed web app.')
output webAppName string = webapp.outputs.webAppName

@description('Default hostname of the deployed web app.')
output webAppHostName string = webapp.outputs.defaultHostName

@description('Name of the Azure SQL logical server.')
output sqlServerName string = database.outputs.sqlServerName

@description('Name of the Azure SQL database.')
output databaseName string = database.outputs.databaseName

@description('Resource id of the Log Analytics workspace.')
output logAnalyticsWorkspaceId string = monitoring.outputs.logAnalyticsWorkspaceId

@description('Name of the workspace-based Application Insights component.')
output applicationInsightsName string = monitoring.outputs.applicationInsightsName

@description('Name of the managed identity used for database bootstrap.')
output databaseBootstrapIdentityName string = identityBootstrap.outputs.name
