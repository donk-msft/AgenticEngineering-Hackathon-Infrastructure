metadata description = 'Operational alert rules and readiness availability test for Contoso Ticketing, composed from Azure Verified Modules.'

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

module readinessTest 'br/public:avm/res/insights/webtest:0.3.2' = {
  name: 'readiness-webtest'
  params: {
    name: readinessTestName
    webTestName: readinessTestName
    appInsightResourceId: applicationInsightsResourceId
    location: location
    tags: tags
    description: 'Validates that the application can reach SQL through private networking and managed identity.'
    kind: 'standard'
    enabled: true
    frequency: 300
    timeout: 30
    retryEnabled: true
    locations: [
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
    request: {
      RequestUrl: 'https://${webAppHostName}/readyz'
      HttpVerb: 'GET'
      FollowRedirects: true
      ParseDependentRequests: false
    }
    validationRules: {
      ExpectedHttpStatusCode: 200
      IgnoreHttpStatusCode: false
      SSLCheck: true
      SSLCertRemainingLifetimeCheck: 7
    }
  }
}

module http5xxAlert 'br/public:avm/res/insights/metric-alert:0.4.1' = {
  name: 'alert-app-http5xx'
  params: {
    name: 'alert-app-http5xx-${suffix}'
    alertDescription: 'App Service returned more than five HTTP 5xx responses in five minutes.'
    severity: 2
    enabled: true
    tags: tags
    scopes: [
      webAppResourceId
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allof: [
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
  }
}

module responseTimeAlert 'br/public:avm/res/insights/metric-alert:0.4.1' = {
  name: 'alert-app-response'
  params: {
    name: 'alert-app-response-${suffix}'
    alertDescription: 'App Service average response time exceeded three seconds over five minutes.'
    severity: 3
    enabled: true
    tags: tags
    scopes: [
      webAppResourceId
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allof: [
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
  }
}

module healthCheckAlert 'br/public:avm/res/insights/metric-alert:0.4.1' = {
  name: 'alert-app-health'
  params: {
    name: 'alert-app-health-${suffix}'
    alertDescription: 'App Service health-check status for /healthz fell below 100 percent.'
    severity: 1
    enabled: true
    tags: tags
    scopes: [
      webAppResourceId
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allof: [
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
  }
}

module readinessAlert 'br/public:avm/res/insights/metric-alert:0.4.1' = {
  name: 'alert-app-readyz'
  params: {
    name: 'alert-app-readyz-${suffix}'
    alertDescription: 'The /readyz availability test failed from at least two test locations.'
    severity: 1
    enabled: true
    tags: union(tags, {
      'hidden-link:${applicationInsightsResourceId}': 'Resource'
      'hidden-link:${readinessTest.outputs.resourceId}': 'Resource'
    })
    scopes: [
      readinessTest.outputs.resourceId
      applicationInsightsResourceId
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.WebtestLocationAvailabilityCriteria'
      webTestResourceId: readinessTest.outputs.resourceId
      componentResourceId: applicationInsightsResourceId
      failedLocationCount: 2
    }
  }
}

module sqlCpuAlert 'br/public:avm/res/insights/metric-alert:0.4.1' = {
  name: 'alert-sql-cpu'
  params: {
    name: 'alert-sql-cpu-${suffix}'
    alertDescription: 'Azure SQL average CPU exceeded 85 percent over the supported 15-minute window.'
    severity: 3
    enabled: true
    tags: tags
    scopes: [
      databaseResourceId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allof: [
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
  }
}
