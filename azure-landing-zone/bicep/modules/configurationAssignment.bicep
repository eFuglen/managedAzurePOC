targetScope = 'subscription'
param location string = 'global'
param configurationAssignmentName string
param filterLocations array = []
param filterOsTypes array = []
param filterResourceGroups array = []
param filterResourceTypes array = []
param filterTags object = {}
param maintenanceConfigurationId string


resource configurationAssignment 'Microsoft.Maintenance/configurationAssignments@2023-10-01-preview' = {
  location: location
  name: configurationAssignmentName
  properties: {
    filter: {
      locations: filterLocations
      osTypes: filterOsTypes
      resourceGroups: filterResourceGroups
      resourceTypes: filterResourceTypes
      tagSettings: filterTags
    }
    maintenanceConfigurationId: maintenanceConfigurationId
  }
}
