@description('Name of the Log Analytics workspace')
param workspaceName string

@description('Environment name used for resource naming')
param environmentName string

@description('Location for the Log Analytics workspace')
param location string

@description('The pricing tier for the Log Analytics workspace')
param pricingTier string = 'PerGB2018'

@description('Tags to apply to the Log Analytics workspace')
param tags object

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: 'la-${workspaceName}-${environmentName}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: pricingTier
    }
    retentionInDays: 30
  }
}

output id string = logAnalyticsWorkspace.id
output name string = logAnalyticsWorkspace.name
