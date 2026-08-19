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
param workload string = 'ticketing'

@description('Environment short name.')
@allowed([
  'dev'
  'tst'
  'prd'
])
param environment string = 'dev'

@description('Azure region for all resources. Use a region where the Azure SRE Agent is available if you plan to do the expert track.')
param location string = 'swedencentral'

@description('Owner tag value (team or e-mail address).')
param owner string = 'hackathon-team'

@description('Cost centre tag value.')
param costCenter string = 'hackathon'

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

module identityApp 'modules/identity-app.bicep' = {
  scope: rg
  name: 'identity-app'
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
    appIdentityResourceId: identityApp.outputs.resourceId
    appIdentityPrincipalId: identityApp.outputs.principalId
    appIdentityClientId: identityApp.outputs.clientId
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
    webAppClientId: identityApp.outputs.clientId
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

output resourceGroupName string = rg.name
output webAppName string = webapp.outputs.webAppName
output webAppHostName string = webapp.outputs.defaultHostName
output sqlServerName string = database.outputs.sqlServerName
output databaseName string = database.outputs.databaseName
output logAnalyticsWorkspaceId string = monitoring.outputs.logAnalyticsWorkspaceId
output applicationInsightsName string = monitoring.outputs.applicationInsightsName
output databaseBootstrapIdentityName string = identityBootstrap.outputs.name
