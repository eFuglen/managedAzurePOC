targetScope = 'subscription'

@description('The resource group configuration object')
param resourceGroupName string

@description('Common tags to apply to the resource group')
param tags object = {}

@description('The location for the resource group')
param location string

// Deploy resource group
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Output the resource group details
output resourceGroupName string = rg.name
output resourceGroupId string = rg.id
output resourceGroup object = {
  name: rg.name
  id: rg.id
  location: rg.location
}
