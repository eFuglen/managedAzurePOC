param dcrName string
param location string = resourceGroup().location
param dcrDescription string
param laWorkspaceId string
param dcrDestionationName string
param dcrPerfCounters array = []
param dcrExtensions array = []
param dcrDataFlows array = []
param laWorkspaceName string = ''
param changeTrackingSolution bool = false

resource dataCollectionRule 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: dcrName
  location: location
  properties: {
    description: dcrDescription
    dataSources: {
      performanceCounters: dcrPerfCounters
      extensions: dcrExtensions
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: laWorkspaceId
          name: dcrDestionationName
        }
      ]
    }
    dataFlows: dcrDataFlows
  }
}

resource solution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = if (changeTrackingSolution) {
  name: 'ChangeTracking(${laWorkspaceName})'
  location: location
  properties: {
    workspaceResourceId: laWorkspaceId
  }
  plan: {
    name: 'ChangeTracking(${laWorkspaceName})'
    product: 'OMSGallery/ChangeTracking'
    promotionCode: ''
    publisher: 'Microsoft'
  }
}

output id string = dataCollectionRule.id

