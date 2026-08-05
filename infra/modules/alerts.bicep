metadata description = 'Operational alert rules and readiness availability test for Contoso Ticketing, implemented with native Azure Monitor resources.'

@description('Workload name used in CAF resource names.')
param workload string

@description('Environment short name.')
param environment string

@description('Azure region.')
param location string

@description('Tags applied to all resources.')
param tags object

@description('App Service resource name.')
param webAppName string

@description('App Service default hostname.')
param webAppHostName string

@description('Azure SQL logical server name.')
param sqlServerName string

@description('Azure SQL database name.')
param databaseName string

@description('Application Insights component name.')
param applicationInsightsName string

var suffix = '${workload}-${environment}-${location}'
var webAppResourceId = resourceId('Microsoft.Web/sites', webAppName)
var databaseResourceId = resourceId('Microsoft.Sql/servers/databases', sqlServerName, databaseName)
var applicationInsightsResourceId = resourceId('Microsoft.Insights/components', applicationInsightsName)
var readinessTestName = 'webtest-readyz-${suffix}'

resource readinessTest 'Microsoft.Insights/webtests@2022-06-15' = {
  name: readinessTestName
  location: location
  kind: 'standard'
  tags: union(tags, {
    'hidden-link:${applicationInsightsResourceId}': 'Resource'
  })
  properties: {
    SyntheticMonitorId: readinessTestName
    Name: readinessTestName
    Description: 'Validates that the application can reach SQL through private networking and managed identity.'
    Enabled: true
    Frequency: 300
    Timeout: 30
    Kind: 'standard'
    RetryEnabled: true
    Locations: [
      {
        Id: 'emea-nl-ams-azr'
      }
      {
        Id: 'emea-se-sto-edge'
      }
      {
        Id: 'emea-gb-db3-azr'
      }
    ]
    Request: {
      RequestUrl: 'https://${webAppHostName}/readyz'
      HttpVerb: 'GET'
      FollowRedirects: true
      ParseDependentRequests: false
    }
    ValidationRules: {
      ExpectedHttpStatusCode: 200
      IgnoreHttpStatusCode: false
      SSLCheck: true
      SSLCertRemainingLifetimeCheck: 7
    }
  }
}

resource http5xxAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-app-http5xx-${suffix}'
  location: 'global'
  tags: tags
  properties: {
    description: 'App Service returned more than five HTTP 5xx responses in five minutes.'
    severity: 2
    enabled: true
    scopes: [
      webAppResourceId
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'Http5xxThreshold'
          metricNamespace: 'Microsoft.Web/sites'
          metricName: 'Http5xx'
          dimensions: []
          operator: 'GreaterThan'
          threshold: 5
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: []
  }
}

resource responseTimeAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-app-response-${suffix}'
  location: 'global'
  tags: tags
  properties: {
    description: 'App Service average response time exceeded three seconds over five minutes.'
    severity: 3
    enabled: true
    scopes: [
      webAppResourceId
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'AverageResponseTimeThreshold'
          metricNamespace: 'Microsoft.Web/sites'
          metricName: 'AverageResponseTime'
          dimensions: []
          operator: 'GreaterThan'
          threshold: 3
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: []
  }
}

resource healthCheckAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-app-health-${suffix}'
  location: 'global'
  tags: tags
  properties: {
    description: 'App Service health-check status for /healthz fell below 100 percent.'
    severity: 1
    enabled: true
    scopes: [
      webAppResourceId
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HealthCheckStatusThreshold'
          metricNamespace: 'Microsoft.Web/sites'
          metricName: 'HealthCheckStatus'
          dimensions: []
          operator: 'LessThan'
          threshold: 1
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: []
  }
}

resource readinessAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-app-readyz-${suffix}'
  location: 'global'
  tags: union(tags, {
    'hidden-link:${applicationInsightsResourceId}': 'Resource'
    'hidden-link:${readinessTest.id}': 'Resource'
  })
  properties: {
    description: 'The /readyz availability test failed from at least two test locations.'
    severity: 1
    enabled: true
    scopes: [
      readinessTest.id
      applicationInsightsResourceId
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.WebtestLocationAvailabilityCriteria'
      webTestId: readinessTest.id
      componentId: applicationInsightsResourceId
      failedLocationCount: 2
    }
    actions: []
  }
}

resource sqlCpuAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-sql-cpu-${suffix}'
  location: 'global'
  tags: tags
  properties: {
    description: 'Azure SQL average CPU exceeded 85 percent over the supported 15-minute window.'
    severity: 3
    enabled: true
    scopes: [
      databaseResourceId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'CpuThreshold'
          metricNamespace: 'Microsoft.Sql/servers/databases'
          metricName: 'cpu_percent'
          dimensions: []
          operator: 'GreaterThan'
          threshold: 85
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: []
  }
}
