targetScope= 'subscription'

@description('Array of Resource Groups to be created or updated')
param resourceGroups array
@description('Tags which are static for resource groups')
param defaultTags object

module monitoringResourceGroup 'addResourceGroup.bicep' = [ for (rg, i) in resourceGroups : {
  scope: subscription()
  name: 'CreateUpdate-${rg.name}'
  params: {
    location: rg.location
    resourceGroupName: rg.name
    resourceTags: defaultTags
  }
}]
