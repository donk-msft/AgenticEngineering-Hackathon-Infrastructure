metadata description = 'Monitoring for the Contoso Ticketing workload: Log Analytics and workspace-based Application Insights, built from Azure Verified Modules.'

@description('Workload name used in CAF resource names.')
param workload string

@description('Environment short name.')
param environment string

@description('Azure region.')
param location string

@description('Tags applied to all resources.')
param tags object

var suffix = '${workload}-${environment}-${location}'

module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.16.1' = {
  name: 'law-${suffix}'
  params: {
    name: 'log-${suffix}'
    location: location
    tags: tags
    skuName: 'PerGB2018'
    dataRetention: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

module applicationInsights 'br/public:avm/res/insights/component:0.8.0' = {
  name: 'appi-${suffix}'
  params: {
    name: 'appi-${suffix}'
    location: location
    tags: tags
    applicationType: 'web'
    kind: 'web'
    workspaceResourceId: logAnalytics.outputs.resourceId
    retentionInDays: 30
  }
}

output logAnalyticsWorkspaceId string = logAnalytics.outputs.resourceId
output logAnalyticsWorkspaceName string = logAnalytics.outputs.name
output applicationInsightsName string = applicationInsights.outputs.name

@description('Application Insights connection string. Treated as a configuration value, not a secret credential.')
#disable-next-line outputs-should-not-contain-secrets
output applicationInsightsConnectionString string = applicationInsights.outputs.connectionString
