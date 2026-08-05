metadata description = 'Data tier for the Contoso Ticketing workload: Azure SQL with public access disabled, Entra-only authentication and a private endpoint with private DNS, built from Azure Verified Modules.'

@description('Workload name used in CAF resource names.')
param workload string

@description('Environment short name.')
param environment string

@description('Azure region.')
param location string

@description('Tags applied to all resources.')
param tags object

@description('Subnet that hosts the SQL private endpoint.')
param privateEndpointSubnetId string

@description('Virtual network linked to the private DNS zone.')
param virtualNetworkId string

@description('Microsoft Entra object id of the SQL Server administrator.')
param sqlAdminObjectId string

@description('Display name of the Microsoft Entra principal that becomes the SQL Server administrator.')
param sqlAdminLogin string

var suffix = '${workload}-${environment}-${location}'
var sqlServerName = 'sql-${suffix}'
var databaseName = 'sqldb-${suffix}'

module privateDnsZone 'br/public:avm/res/network/private-dns-zone:0.8.1' = {
  name: 'pdns-sql-${suffix}'
  params: {
    name: 'privatelink${az.environment().suffixes.sqlServerHostname}'
    tags: tags
    virtualNetworkLinks: [
      {
        name: 'link-${suffix}'
        virtualNetworkResourceId: virtualNetworkId
        registrationEnabled: false
      }
    ]
  }
}

module sqlServer 'br/public:avm/res/sql/server:0.22.0' = {
  name: 'sql-${suffix}'
  params: {
    name: sqlServerName
    location: location
    tags: tags
    managedIdentities: {
      systemAssigned: true
    }
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: true
      // For principalType 'User', `login` should be the user's UPN (e.g., `az ad signed-in-user show --query userPrincipalName -o tsv`).
      principalType: 'User'
      login: sqlAdminLogin
      tenantId: tenant().tenantId
    }
    databases: [
      {
        name: databaseName
        tags: tags
        sku: {
          name: 'GP_S_Gen5'
          tier: 'GeneralPurpose'
          family: 'Gen5'
          capacity: 1
        }
        autoPauseDelay: 60
        minCapacity: '0.5'
        zoneRedundant: false
        availabilityZone: -1
      }
    ]
    privateEndpoints: [
      {
        name: 'pep-${sqlServerName}'
        service: 'sqlServer'
        subnetResourceId: privateEndpointSubnetId
        tags: tags
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: privateDnsZone.outputs.resourceId
            }
          ]
        }
      }
    ]
  }
}

output sqlServerName string = sqlServer.outputs.name
output databaseName string = databaseName

@description('Passwordless connection string. Authentication happens through the web app managed identity, so no secret is emitted.')
output connectionString string = 'Server=tcp:${sqlServer.outputs.fullyQualifiedDomainName},1433;Database=${databaseName};Authentication=Active Directory Default;Encrypt=True;TrustServerCertificate=False;'
