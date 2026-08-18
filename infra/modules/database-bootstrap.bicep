metadata description = 'Automated database bootstrap for the Contoso Ticketing workload: a VNet-integrated deploymentScript that creates the application database principal and Tickets table using the sole SQL Entra administrator managed identity, built from Azure Verified Modules.'

@description('Workload name used in CAF resource names.')
param workload string

@description('Environment short name.')
param environment string

@description('Azure region.')
param location string

@description('Tags applied to all resources.')
param tags object

@description('Subnet delegated to Microsoft.ContainerInstance/containerGroups that hosts the deployment script container.')
param deployScriptSubnetId string

@description('Resource id of the user-assigned managed identity used to run the script and administer SQL.')
param managedIdentityResourceId string

@description('Principal id of the user-assigned managed identity, used for the storage role assignment.')
param managedIdentityPrincipalId string

@description('Client id of the user-assigned managed identity, used to authenticate to SQL.')
param managedIdentityClientId string

@description('SQL logical server name.')
param sqlServerName string

@description('SQL database name.')
param databaseName string

@description('Web app name whose managed identity receives db_datareader access.')
param webAppName string

@description('Object id of the web app system-assigned managed identity.')
param webAppPrincipalId string

@description('Forces the deployment script to re-run on every deployment. Defaults to the current UTC timestamp.')
param baseTime string = utcNow()

var suffix = '${workload}-${environment}-${location}'
// Storage account name must be <=24 chars, lowercase alphanumeric only.
var storageAccountName = take('stdbboot${uniqueString(resourceGroup().id, suffix)}', 24)

// Deployment scripts running in a private network require an existing storage account
// with shared key access enabled and network access scoped to the container subnet.
// See: https://learn.microsoft.com/azure/azure-resource-manager/bicep/deployment-script-vnet
module storageAccount 'br/public:avm/res/storage/storage-account:0.33.0' = {
  name: 'st-dbboot-${suffix}'
  params: {
    name: storageAccountName
    location: location
    tags: tags
    skuName: 'Standard_LRS'
    kind: 'StorageV2'
    allowSharedKeyAccess: true
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: deployScriptSubnetId
          action: 'Allow'
        }
      ]
    }
  }
}

var storageFileDataPrivilegedContributorRoleId = '69566ab7-960f-475b-8e7c-b3118f30c6bd'

resource storageAccountExisting 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
  dependsOn: [
    storageAccount
  ]
}

resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccountExisting.id, managedIdentityPrincipalId, storageFileDataPrivilegedContributorRoleId)
  scope: storageAccountExisting
  properties: {
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageFileDataPrivilegedContributorRoleId)
  }
}

// The published AVM module references Microsoft.Resources/deploymentScripts@2021-12-01 in an
// internal (unused) type reference, which triggers BCP081 even though the actual deployed API
// version (2023-08-01) is fully typed. Suppressed because this warning originates in the AVM
// module itself, not in this file.
#disable-next-line BCP081
module databaseBootstrapScript 'br/public:avm/res/resources/deployment-script:0.5.2' = {
  name: 'ds-dbboot-${suffix}'
  params: {
    name: 'ds-dbboot-${suffix}'
    location: location
    tags: tags
    kind: 'AzureCLI'
    azCliVersion: '2.65.0'
    managedIdentities: {
      userAssignedResourceIds: [
        managedIdentityResourceId
      ]
    }
    storageAccountResourceId: storageAccount.outputs.resourceId
    subnetResourceIds: [
      deployScriptSubnetId
    ]
    scriptContent: loadTextContent('../../scripts/bootstrap-ticketing-database-deploymentscript.sh')
    environmentVariables: [
      {
        name: 'SQL_SERVER_NAME'
        value: sqlServerName
      }
      {
        name: 'DATABASE_NAME'
        value: databaseName
      }
      {
        name: 'WEB_APP_NAME'
        value: webAppName
      }
      {
        name: 'WEB_APP_PRINCIPAL_ID'
        value: webAppPrincipalId
      }
      {
        name: 'MANAGED_IDENTITY_CLIENT_ID'
        value: managedIdentityClientId
      }
    ]
    retentionInterval: 'P1D'
    cleanupPreference: 'OnSuccess'
    timeout: 'PT30M'
    runOnce: false
    baseTime: baseTime
  }
  dependsOn: [
    storageRoleAssignment
  ]
}
