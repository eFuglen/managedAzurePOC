param configurationName string = 'maintenanceConf'
param location string = resourceGroup().location
param inGuestPatchMode string = 'User'
param maintenanceScope string = 'InGuestPatch'
param maintenanceWindow object = {
  startDateTime: '2025-01-01 11:30'
  duration: '03:55'
  timeZone: 'Romance Standard Time'
  recurEvery: '1Week Friday'
}
@allowed(['Always', 'IfRequired', 'Never'])
param rebootSetting string = 'IfRequired'
param windowsClasificationsToInclude array = [
  'Critical'
  'Security'
  'UpdateRollup'
  'ServicePack'
  'Definition'
  'Updates'
]
param linuxClasificationsToInclude array = [
  'Critical'
  'Security'
  'Other'
]
param assignmentFilterLocations array = []
param assignmentFilterOSTypes array = [
  'Windows'
  'Linux'
]
param assignmentFilterRG array
param assignmentFilterResourceTypes array = [
  'microsoft.hybridcompute/machines'
]
param assignmentTagFilterOperator string = 'All'
param assignmentTagFilter object = {}

var configurationAssignmentName = '${configurationName}-Assignment'

resource maintenanceconfiguration 'Microsoft.Maintenance/maintenanceConfigurations@2023-10-01-preview' = {
  name: configurationName
  location: location
  properties: {
    extensionProperties: {
      inGuestPatchMode: inGuestPatchMode
    }
    maintenanceScope: maintenanceScope
    maintenanceWindow: maintenanceWindow
    installPatches: {
      rebootSetting: rebootSetting
      windowsParameters: {
        classificationsToInclude: windowsClasificationsToInclude
      }
      linuxParameters: {
        classificationsToInclude: linuxClasificationsToInclude
      }
    }
  }
}

module configurationAssignment 'configurationAssignment.bicep' = {
  name: configurationAssignmentName
  scope: subscription()
  params: {
    configurationAssignmentName: configurationAssignmentName
    filterLocations: assignmentFilterLocations
    filterOsTypes: assignmentFilterOSTypes
    filterResourceGroups: assignmentFilterRG
    filterResourceTypes: assignmentFilterResourceTypes
    filterTags: {
      filterOperator: assignmentTagFilterOperator
      tags: assignmentTagFilter
    }
    maintenanceConfigurationId: maintenanceconfiguration.id
  }
}
