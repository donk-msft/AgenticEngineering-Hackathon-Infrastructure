metadata description = 'User-assigned managed identity for the App Service workload principal used by the web app and SQL contained-user bootstrap.'

@description('Workload name used in CAF resource names.')
param workload string

@description('Environment short name.')
param environment string

@description('Azure region.')
param location string

@description('Tags applied to all resources.')
param tags object

var suffix = '${workload}-${environment}-${location}'
var identityName = 'id-app-${suffix}'

module userAssignedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.6.0' = {
  name: 'id-app-${suffix}'
  params: {
    name: identityName
    location: location
    tags: tags
  }
}

output resourceId string = userAssignedIdentity.outputs.resourceId
output principalId string = userAssignedIdentity.outputs.principalId
output clientId string = userAssignedIdentity.outputs.clientId
output name string = userAssignedIdentity.outputs.name
