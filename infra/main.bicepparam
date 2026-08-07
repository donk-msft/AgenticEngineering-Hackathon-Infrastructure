using 'main.bicep'

param workload = 'ticketing'
param environment = 'dev'
param location = 'swedencentral'
param owner = 'hackathon-team'
param costCenter = 'hackathon'

// Replace with the object id and display name of the Microsoft Entra group that
// should administer the SQL Server. Reuse an existing group or create the example group:
//   az ad group create --display-name "sg-hackathon-sqladmins" --mail-nickname "sg-hackathon-sqladmins"
// Then find its values with:
//   az ad group show --group "sg-hackathon-sqladmins" --query "{id:id, name:displayName}"
param sqlAdminObjectId = '00000000-0000-0000-0000-000000000000'
param sqlAdminLogin = 'sg-hackathon-sqladmins'
param sqlAdminPrincipalType = 'Group'
