using '../main.bicep'

param subscriptionId = ''

param resourceGroups = [
  {
    name: 'monitoringRG-${toUpper(environmentName)}'
    type: 'Monitor'
    location: location
    managedResources: false
  }
  {
    name: 'sharedRG-${toUpper(environmentName)}'
    type: 'Shared'
    location: location
    managedResources: false
  }
  {
    name: 'uamiRG-${toUpper(environmentName)}'
    type: 'UAMI'
    location: location
    managedResources: false
  }
  {
    name: 'windowsVmRG-${toUpper(environmentName)}'
    type: 'Shared'
    location: location
    managedResources: true
  }
  {
    name: 'sqlVmRG-${toUpper(environmentName)}'
    type: 'Shared'
    location: location
    managedResources: true
  }
]
param location = 'swedencentral'
param environmentName = 'Prod'
param projectName = 'lz'
param version = '0.0.1'
param tags = {
  Environment: environmentName
  Project: projectName
  DeployedBy: 'Bicep'
  Version: version
}

// Guest Configuration parameters
param guestConfigurationName = 'TimeZone'
param guestConfigurationVersion = '1.0.0'
param guestConfigurationContentUri = 'https://example.com/guestconfig/TimeZone.zip'
param guestConfigurationContentHash = ''
param guestConfigTagName = 'GuestConfig'
param guestConfigTagValues = ['Applied']
