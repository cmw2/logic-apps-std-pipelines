param location string
param environmentName string
param projectName string

@minLength(3)
@maxLength(24)
param storageName string
param storageKind string = 'StorageV2'
param storageSKU string = 'Standard_LRS'

param appPlanName string
param appPlanSKU string = 'WS1'
param appPlanSKUTier string = 'WorkflowStandard'
param logAnalyticsName string
param appInsName string
param logicAppName string


resource storAcct 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageName
  location: location
  kind: storageKind
  sku: {
    name: storageSKU
  }
  tags: {
    Project: projectName
    Environment: environmentName
  }
}

resource appPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: appPlanName
  location: location
  kind: 'elastic'
  sku: {
    name: appPlanSKU
    tier: appPlanSKUTier
  }
  tags: {
    Project: projectName
    Environment: environmentName
  }
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: logAnalyticsName
  location: location
  tags: {
    Project: projectName
    Environment: environmentName
  }
}

resource appIns 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsName
  location: location
  kind: 'web'
  tags: {
    Project: projectName
    Environment: environmentName
  }
  properties: {
    Application_Type: 'web'
    RetentionInDays: 90
    WorkspaceResourceId: logAnalytics.id
    IngestionMode: 'LogAnalytics'
  }
}

resource logicApp 'Microsoft.Web/sites@2021-03-01' = {
  name: logicAppName
  location: location
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    Project: projectName
    Environment: environmentName
  }
  properties: {
    serverFarmId: appPlan.id
    siteConfig: {
      netFrameworkVersion: 'v4.6'
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appIns.properties.InstrumentationKey
        }
        {
          name: 'ENVIRONMENT_NAME'
          value: environmentName
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageName};AccountKey=${listKeys('${resourceGroup().id}/providers/Microsoft.Storage/storageAccounts/${storageName}', '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageName};AccountKey=${listKeys('${resourceGroup().id}/providers/Microsoft.Storage/storageAccounts/${storageName}', '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: logicAppName
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~12'
        }
        {
          name: 'WORKFLOWS_SUBSCRIPTION_ID'
          value: subscription().subscriptionId
        }
        {
          name: 'WORKFLOWS_LOCATION_NAME'
          value: location
        }
        {
          name: 'WORKFLOWS_RESOURCE_GROUP_NAME'
          value: resourceGroup().name
        }
      ]
    }
  }
  dependsOn: [
    storAcct
  ]
}

output logicAppSystemAssignedIdentityTenantId string = subscription().tenantId
output logicAppSystemAssignedIdentityObjectId string = reference(logicApp.id, '2021-03-01', 'full').identity.principalId
output LAname string = logicAppName


