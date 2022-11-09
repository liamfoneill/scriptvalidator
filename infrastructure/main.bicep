param location string = 'uksouth'
@description('The name of the logic app to create.')
param logicAppName string = 'blobToMessage'

@description('A test URI')
param testUri string = 'https://status.azure.com/en-us/status/'


var frequency = 'Hour'
var interval = '1'
var type = 'recurrence'
var actionType = 'http'
var method = 'GET'
var workflowSchema = 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'

resource storageaccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: 'nigdsg34235'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Premium_LRS'
  }
}

resource stg 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: {
    displayName: logicAppName
  }
  properties: {
    definition: {
      '$schema': workflowSchema
      contentVersion: '1.0.0.0'
      parameters: {
        testUri: {
          type: 'string'
          defaultValue: testUri
        }
      }
      triggers: {
        recurrence: {
          type: type
          recurrence: {
            frequency: frequency
            interval: interval
          }
        }
      }
      actions: {
        actionType: {
          type: actionType
          inputs: {
            method: method
            uri: testUri
          }
        }
      }
    }
  }
}

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' = {
  name: 'examscripts'
  location: location
  sku: {
    name: 'Standard'
    capacity: 1
    tier: 'Standard'
  }
}

resource serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2022-01-01-preview' = {
  name: 'examScriptQueue'
  parent: serviceBusNamespace
  properties: {
    lockDuration: 'PT5M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P10675199DT2H48M5.4775807S'
    deadLetteringOnMessageExpiration: false
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: false
    enableExpress: false
  }
}

resource serviceBusTopicMath 'Microsoft.ServiceBus/namespaces/topics@2022-01-01-preview' = {
  name: 'mathTopic'
  parent: serviceBusNamespace
  properties: {
  }
}

resource serviceBusTopicEnglish 'Microsoft.ServiceBus/namespaces/topics@2022-01-01-preview' = {
  name: 'englishTopic'
  parent: serviceBusNamespace
  properties: {
  }
}

resource webApplication 'Microsoft.Web/sites@2021-01-15' = {
  name: 'scriptValidatorWebApp'
  location: location
  tags: {
    'hidden-related:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/appServicePlan': 'Resource'
  }
  properties: {
    serverFarmId: appServicePlan.id
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'scriptValidatorASP'
  location: location
  sku: {
    name: 'S1'
  }
  properties: {
    reserved: true
  }
}

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' ={
  name: 'examscriptvalidator22'
  location: location
  properties: {
    administratorLogin: 'sqladmin'
    administratorLoginPassword: 'Ch@ng3m3!'
  }
}

resource sqlServerDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: 'validatorDB'
  location: location
  properties: {
  }
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

resource signalR 'Microsoft.SignalRService/signalR@2022-08-01-preview' = {
  name: 'examscriptvalidator'
  location: location
  properties: {
    features: [
      {
        flag: 'ServiceMode'
        value: 'Default'
      }
      {
        flag: 'EnableConnectivityLogs'
        value: 'true'
      }
    ]
  }
  sku: {
    name: 'Premium_P1'
    tier: 'Premium'
    capacity: 1
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'examScriptsLogs'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource appInsightsComponents 'Microsoft.Insights/components@2020-02-02' = {
  name: 'examValidatorInsights'
  location: location
  kind: ''
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'IbizaAIExtension'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}



