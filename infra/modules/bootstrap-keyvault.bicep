metadata description = 'RBAC-enabled Key Vault for the bootstrap VM SSH private key used by Azure Bastion.'

@description('Workload name used in CAF resource names.')
param workload string

@description('Environment short name.')
param environment string

@description('Azure region.')
param location string

@description('Tags applied to the Key Vault.')
param tags object

var vaultName = 'kv-${workload}-${environment}-${take(toLower(location), 4)}'

module keyVault 'br/public:avm/res/key-vault/vault:0.9.0' = {
  name: 'kv-${workload}-${environment}-${take(toLower(location), 4)}'
  params: {
    name: vaultName
    location: location
    tags: tags
    enableRbacAuthorization: true
    enablePurgeProtection: true
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

output name string = keyVault.outputs.name
output resourceId string = keyVault.outputs.resourceId
