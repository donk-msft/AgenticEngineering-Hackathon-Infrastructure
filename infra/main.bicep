targetScope = 'subscription'

metadata description = '''
Shared hackathon baseline: the "Contoso Ticketing" workload.

Every track (beginner, intermediate, expert) deploys this same architecture, so a
team that finishes the beginner or intermediate track can roll straight into the
expert track without redesigning the workload.
'''

@description('Workload name used in CAF resource names, e.g. rg-<workload>-<env>-<region>.')
@minLength(3)
@maxLength(12)
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

@description('Microsoft Entra object id that becomes the SQL Server Entra administrator.')
param sqlAdminObjectId string

@description('Display name of the Microsoft Entra principal that becomes the SQL Server administrator.')
param sqlAdminLogin string

@description('Microsoft Entra principal type of the SQL Server administrator.')
@allowed([
  'Group'
  'Application'
  'User'
])
param sqlAdminPrincipalType string = 'User'

@description('Linux administrator username for the private bootstrap VM.')
param bootstrapVmAdminUsername string = 'azureuser'

@description('SSH public key for the private bootstrap VM administrator.')
param bootstrapVmSshPublicKey string

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
    sqlAdminObjectId: sqlAdminObjectId
    sqlAdminLogin: sqlAdminLogin
    sqlAdminPrincipalType: sqlAdminPrincipalType
  }
}

module bootstrapKeyVault 'modules/bootstrap-keyvault.bicep' = {
  scope: rg
  name: 'bootstrap-keyvault'
  params: {
    workload: workload
    environment: environment
    location: location
    tags: tags
  }
}

module bootstrapVm 'modules/bootstrap-vm.bicep' = {
  scope: rg
  name: 'bootstrap-vm'
  params: {
    workload: workload
    environment: environment
    location: location
    tags: tags
    bootstrapSubnetId: networking.outputs.bootstrapSubnetId
    virtualNetworkId: networking.outputs.virtualNetworkId
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    adminUsername: bootstrapVmAdminUsername
    adminSshPublicKey: bootstrapVmSshPublicKey
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
output bootstrapKeyVaultName string = bootstrapKeyVault.outputs.name
output bootstrapKeyVaultResourceId string = bootstrapKeyVault.outputs.resourceId
output bootstrapVmName string = bootstrapVm.outputs.bootstrapVmName
output bootstrapVmResourceId string = bootstrapVm.outputs.bootstrapVmResourceId
output bootstrapVmAdminUsername string = bootstrapVm.outputs.bootstrapVmAdminUsername
output bastionName string = bootstrapVm.outputs.bastionName
output bastionResourceId string = bootstrapVm.outputs.bastionResourceId
