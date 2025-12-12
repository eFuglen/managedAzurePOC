targetScope = 'subscription'

@description('Name of the Resource Group to create or update')
param resourceGroupName string
@description('Azure region for the Resource Group')
param location string
@description('Tags to apply to the Resource Group')
param resourceTags object

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: resourceGroupName
  location: location
  tags: resourceTags
}
