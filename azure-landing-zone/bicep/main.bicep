// Main Bicep template for Azure Landing Zone
// Deploys resources for: Monitoring, Backup, Patching, and Azure Machine Configuration Management

targetScope = 'managementGroup'

@description('Subscription ID where resources will be deployed')
param subscriptionId string

@description('The location where resources will be deployed')
param location string = 'swedencentral'

@description('Environment name (dev, test, prod)')
param environmentName string = 'prod'

@description('Project name used for resource naming')
param projectName string = 'managed'

@description('Version of the deployment')
param version string = '0.0.1'

@description('Tags to apply to all resources')
param tags object = {
  Environment: environmentName
  Project: projectName
  Version: version
  DeployedBy: 'Bicep'
}

@description('Resource groups to create')
param resourceGroups array = [
  {
    name: '${projectName}-VMs-${environmentName}'
    location: location
  }
]

@description('Tag name used to identify VMs for backup')
param backupTagName string = 'Backup'

@description('Tag values that trigger backup policy assignment')
param backupTagValues array = ['Standard']

@description('Guest Configuration package name')
param guestConfigurationName string = 'TimeZone'

@description('Guest Configuration package version')
param guestConfigurationVersion string = '1.0.0'

@description('Guest Configuration package content URI')
param guestConfigurationContentUri string

@description('Guest Configuration package content hash (SHA256)')
param guestConfigurationContentHash string

@description('Tag name used to identify VMs for guest configuration')
param guestConfigTagName string = 'guestConfig'

@description('Tag values that trigger guest configuration assignment')
param guestConfigTagValues array = ['Applied']

@description('Tag name used to identify VMs for patching')
param patchTagName string = 'Patch'

@description('Tag values that trigger patching assignment')
param patchTagValues array = ['Weekly']

@description('Patch window start date/time (yyyy-MM-dd HH:mm)')
param patchStartDateTime string = '2025-01-01 02:00'

@description('Patch window duration (HH:mm)')
param patchDuration string = '02:00'

@description('Patch window timezone')
param patchTimeZone string = 'UTC'

@description('Patch recurrence, e.g. 1Week Sunday')
param patchRecurEvery string = '1Week Sunday'

var sharedResourceGroupName = first(filter(resourceGroups, x => x.type =~ 'Shared'))!.name
var monitoringResourceGroupName = first(filter(resourceGroups, x => x.type =~ 'Monitor'))!.name
var uamiResourceGroupName = first(filter(resourceGroups, x => x.type =~ 'UAMI'))!.name
var managedRgNames = map(filter(resourceGroups, x => x.managedResources == true), x => x.name)

// Variables for User Assigned Managed Identities
var uamiVmAmaName = 'uami-${projectName}-VmAma'
var uamiGuestConfigName = 'uami-${projectName}-GuestConfig'

// Role Definition IDs for policy remediation
var roleDefinitions = {
  contributor: '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
  userAccessAdministrator: '/providers/Microsoft.Authorization/roleDefinitions/18d7d88d-d35e-4fb5-a5c3-7773c20a72d9'
  virtualMachineContributor: '/providers/Microsoft.Authorization/roleDefinitions/9980e02c-c2be-4d73-94e8-173b1dc7cf3c'
  monitoringContributor: '/providers/Microsoft.Authorization/roleDefinitions/749f88d5-cbae-40b8-bcfc-e573ddc772fa'
  logAnalyticsContributor: '/providers/Microsoft.Authorization/roleDefinitions/92aaf0da-9dab-42b6-94a3-d43ce8d16293'
  backupContributor: '/providers/Microsoft.Authorization/roleDefinitions/5e467623-bb1f-42f4-a55d-6e525e11384b'
  guestConfigurationContributor: '/providers/Microsoft.Authorization/roleDefinitions/088ab73d-1256-47ae-bea9-9de8e7131f31'
  storageBlobDataReader: '/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
}

// ============================================================================
// RESOURCE GROUPS - Create or update resource groups
// ============================================================================

param dateTimeNow string = utcNow('ddMMHHmm')
var resourceGroupDeploymentName = 'rgUpdate-${environmentName}-${dateTimeNow}'

module resourceGroupUpdate 'modules/addUpdateResourceGroups.bicep' = {
  scope: subscription(subscriptionId)
  name: resourceGroupDeploymentName
  params: {
    defaultTags: tags
    resourceGroups: resourceGroups
  }
}

// ============================================================================
// USER ASSIGNED MANAGED IDENTITIES
// ============================================================================

module uamiVmAma 'modules/userAssignedId.bicep' = {
  scope: resourceGroup(subscriptionId,uamiResourceGroupName)
  name: 'uamiVmAmaDeployment'
  params: {
    name: uamiVmAmaName
  }
  dependsOn: [
    resourceGroupUpdate
  ]
}

module uamiGuestConfig 'modules/userAssignedId.bicep' = {
  scope: resourceGroup(subscriptionId, uamiResourceGroupName)
  name: 'uamiGuestConfigDeployment'
  params: {
    name: uamiGuestConfigName
  }
  dependsOn: [
    resourceGroupUpdate
  ]
}

// ============================================================================
// ROLE ASSIGNMENTS FOR POLICY REMEDIATION
// ============================================================================

// Contributor - needed for UAMI assignment policy
module roleAssignmentContributor 'modules/subRoleAssignment.bicep' = {
  scope: subscription(subscriptionId)
  name: 'roleAssignment-Contributor'
  params: {
    targetName: 'uamiVmAma-Contributor'
    principalId: uamiVmAma.outputs.principalId
    roleDefinitionId: roleDefinitions.contributor
  }
}

// User Access Administrator - needed for UAMI assignment policy
module roleAssignmentUserAccessAdmin 'modules/subRoleAssignment.bicep' = {
  scope: subscription(subscriptionId)
  name: 'roleAssignment-UserAccessAdmin'
  params: {
    targetName: 'uamiVmAma-UserAccessAdmin'
    principalId: uamiVmAma.outputs.principalId
    roleDefinitionId: roleDefinitions.userAccessAdministrator
  }
}

// Virtual Machine Contributor - needed for AMA deployment policy
module roleAssignmentVmContributor 'modules/subRoleAssignment.bicep' = {
  scope: subscription(subscriptionId)
  name: 'roleAssignment-VmContributor'
  params: {
    targetName: 'uamiVmAma-VmContributor'
    principalId: uamiVmAma.outputs.principalId
    roleDefinitionId: roleDefinitions.virtualMachineContributor
  }
}

// Monitoring Contributor - needed for DCR association policy
module roleAssignmentMonitoringContributor 'modules/subRoleAssignment.bicep' = {
  scope: subscription(subscriptionId)
  name: 'roleAssignment-MonitoringContributor'
  params: {
    targetName: 'uamiVmAma-MonitoringContributor'
    principalId: uamiVmAma.outputs.principalId
    roleDefinitionId: roleDefinitions.monitoringContributor
  }
}

// Log Analytics Contributor - needed for DCR association policy
module roleAssignmentLogAnalyticsContributor 'modules/subRoleAssignment.bicep' = {
  scope: subscription(subscriptionId)
  name: 'roleAssignment-LogAnalyticsContributor'
  params: {
    targetName: 'uamiVmAma-LogAnalyticsContributor'
    principalId: uamiVmAma.outputs.principalId
    roleDefinitionId: roleDefinitions.logAnalyticsContributor
  }
}

// Storage Blob Data Reader - needed for UAMI to access guest config package
module roleAssignmentStorageBlobReader 'modules/rgRoleAssignment.bicep' = {
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)
  name: 'roleAssignment-GuestConfig-StorageReader'
  params: {
    resourceGroupName: sharedResourceGroupName
    principalId: uamiGuestConfig.outputs.principalId
    roleDefinitionId: roleDefinitions.storageBlobDataReader
  }
}

// Role assignment for guest configuration policy - Virtual Machine Contributor
module roleAssignmentGuestConfigVmContributor 'modules/subRoleAssignment.bicep' = {
  scope: subscription(subscriptionId)
  name: 'roleAssignment-GuestConfig-VmContributor'
  params: {
    targetName: 'guestConfigPolicy-VmContributor'
    principalId: guestConfigPolicyAssignment.outputs.principalId
    roleDefinitionId: roleDefinitions.virtualMachineContributor
  }
}

// Role assignment for guest configuration policy - Guest Configuration Contributor
module roleAssignmentGuestConfigContributor 'modules/subRoleAssignment.bicep' = {
  scope: subscription(subscriptionId)
  name: 'roleAssignment-GuestConfig-Contributor'
  params: {
    targetName: 'guestConfigPolicy-GuestConfigContributor'
    principalId: guestConfigPolicyAssignment.outputs.principalId
    roleDefinitionId: roleDefinitions.guestConfigurationContributor
  }
}

// Role assignment for backup policy - Virtual Machine Contributor
module roleAssignmentBackupVmContributor 'modules/subRoleAssignment.bicep' = {
  scope: subscription(subscriptionId)
  name: 'roleAssignment-Backup-VmContributor'
  params: {
    targetName: 'backupPolicy-VmContributor'
    principalId: backupPolicyAssignment.outputs.principalId
    roleDefinitionId: roleDefinitions.virtualMachineContributor
  }
}

// Role assignment for backup policy - Backup Contributor
module roleAssignmentBackupContributor 'modules/subRoleAssignment.bicep' = {
  scope: subscription(subscriptionId)
  name: 'roleAssignment-Backup-BackupContributor'
  params: {
    targetName: 'backupPolicy-BackupContributor'
    principalId: backupPolicyAssignment.outputs.principalId
    roleDefinitionId: roleDefinitions.backupContributor
  }
}

// ============================================================================
// RESOURCE GROUPS
// ============================================================================

module rgs 'modules/resourceGroup.bicep' = [
  for rgDef in resourceGroups: {
    scope: subscription(subscriptionId)
    name: 'rg-deployment-${rgDef.name}'
    params: {
      resourceGroupName: rgDef.name
      location: rgDef.location
      tags: tags
    }
  }
]

// ============================================================================
// MONITORING - Log Analytics & Data Collection Rules
// ============================================================================

module logAnalytics 'modules/loganalytics.bicep' = {
  scope: resourceGroup(subscriptionId, monitoringResourceGroupName)
  name: 'logAnalytics-deployment'
  params: {
    workspaceName: projectName
    environmentName: environmentName
    location: location
    tags: tags
  }
  dependsOn: [
    resourceGroupUpdate
  ]
}

module performanceDataCollectionRule 'modules/dataCollectionRule.bicep' = {
  scope: resourceGroup(subscriptionId, monitoringResourceGroupName)
  name: 'PerformanceDCR-Deployment'
  params: {
    dcrName: 'PerfandDa-MSVMI-${logAnalytics.outputs.name}'
    dcrDescription: 'Data collection rule for VM Insights.'
    laWorkspaceId: logAnalytics.outputs.id
    dcrDestionationName: 'VMInsightsPerf-Logs-Dest'
    dcrPerfCounters: [
      {
        streams: [
          'Microsoft-InsightsMetrics'
        ]
        samplingFrequencyInSeconds: 60
        counterSpecifiers: [
          '\\VmInsights\\DetailedMetrics'
        ]
        name: 'VMInsightsPerfCounters'
      }
    ]
    dcrDataFlows: [
      {
        streams: [
          'Microsoft-InsightsMetrics'
        ]
        destinations: [
          'VMInsightsPerf-Logs-Dest'
        ]
      }
    ]
  }
  dependsOn: [
    resourceGroupUpdate
  ]
}

// ============================================================================
// BACKUP - Recovery Services Vault & Backup Policy
// ============================================================================

module azureBackup 'modules/backup.bicep' = {
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)
  name: 'azureBackup-deployment'
  params: {
    name: projectName
    location: location
    tags: tags
  }
  dependsOn: [
    resourceGroupUpdate
  ]
}

module vmBackupPolicy 'modules/backupPolicy.bicep' = {
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)
  name: 'vmBackupPolicy-deployment'
  params: {
    vaultName: azureBackup.outputs.name
    policyName: 'VM-Daily-${projectName}-Policy'
    timeZone: 'W. Europe Standard Time'
    backupHour: 2
    backupMinute: 0
    dailyRetentionDays: 30
    enableWeeklyRetention: true
    weeklyRetentionWeeks: 12
    enableMonthlyRetention: true
    monthlyRetentionMonths: 12
    enableYearlyRetention: false
  }
}

// ============================================================================
// AZURE MACHINE CONFIGURATION - Storage Account for DSC configurations
// ============================================================================

module storageAccount 'modules/storageAccount.bicep' = {
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)
  name: 'storageAccount-deployment'
  params: {
    name: 'st${projectName}${toLower(environmentName)}001'
    location: location
    tags: tags
  }
  dependsOn: [
    resourceGroupUpdate
  ]
}

// ============================================================================
// PATCHING - Azure Update Management via Maintenance Configuration
// ============================================================================

module maintenanceConfiguration 'modules/maintenanceconf.bicep' = {
  scope: resourceGroup(subscriptionId, sharedResourceGroupName)
  name: 'maintenance-config-${environmentName}'
  params: {
    configurationName: 'mc-${projectName}-${environmentName}'
    location: location
    maintenanceWindow: {
      startDateTime: patchStartDateTime
      duration: patchDuration
      timeZone: patchTimeZone
      recurEvery: patchRecurEvery
    }
    rebootSetting: 'IfRequired'
    assignmentFilterOSTypes: [
      'Windows'
    ]
    assignmentFilterRG: managedRgNames
    assignmentFilterResourceTypes: [
      'Microsoft.Compute/virtualMachines'
      'Microsoft.Compute/virtualMachineScaleSets'
    ]
    assignmentTagFilterOperator: 'Any'
    assignmentTagFilter: json('{"${patchTagName}":${string(patchTagValues)}}')
  }
  dependsOn: [
    resourceGroupUpdate
  ]
}

// ============================================================================
// POLICIES - Custom policy definitions for AMA deployment
// ============================================================================

// Load policy definitions (static paths)
var assignAMAPolicy = json(loadTextContent('../policies/policyDefinitions/assignAMA-vm.json'))
var assignUAMIPolicy = json(loadTextContent('../policies/policyDefinitions/assignUAMI-vm.json'))
var assignDCRPolicy = json(loadTextContent('../policies/policyDefinitions/assignDCR-vm.json'))
var assignGuestConfigPolicy = json(loadTextContent('../policies/policyDefinitions/assign-guest-configuration.json'))

// Base initiative template (static) for AMA policy set
var basePolicySetContent = json(loadTextContent('../policies/policyDefinitions/deployAMA-custom-set.json'))

// Policy definitions for AMA initiative with actual definition IDs
var amaPolicyDefinitions = [
  {
    policyDefinitionReferenceId: 'AssignUserAssignedManagedIdentity'
    policyDefinitionId: customPolicies.outputs.uamiPolicyId
    parameters: {
      effect: {
        value: '[parameters(\'effect\')]'
      }
      bringYourOwnUserAssignedManagedIdentity: {
        value: '[parameters(\'bringYourOwnUserAssignedManagedIdentity\')]'
      }
      restrictBringYourOwnUserAssignedIdentityToSubscription: {
        value: '[parameters(\'restrictBringYourOwnUserAssignedIdentityToSubscription\')]'
      }
      userAssignedIdentityResourceId: {
        value: '[parameters(\'userAssignedIdentityResourceId\')]'
      }
      userAssignedIdentityName: {
        value: '[parameters(\'userAssignedManagedIdentityName\')]'
      }
      identityResourceGroup: {
        value: '[parameters(\'userAssignedManagedIdentityResourceGroup\')]'
      }
      builtInIdentityResourceGroupLocation: {
        value: '[parameters(\'builtInIdentityResourceGroupLocation\')]'
      }
      enableExclusionTags: {
        value: '[parameters(\'enableExclusionTags\')]'
      }
    }
    groupNames: [
      'Identity'
    ]
  }
  {
    policyDefinitionReferenceId: 'DeployAzureMonitorAgent'
    policyDefinitionId: customPolicies.outputs.amaPolicyId
    parameters: {
      effect: {
        value: '[parameters(\'effect\')]'
      }
      bringYourOwnUserAssignedManagedIdentity: {
        value: '[parameters(\'bringYourOwnUserAssignedManagedIdentity\')]'
      }
      restrictBringYourOwnUserAssignedIdentityToSubscription: {
        value: '[parameters(\'restrictBringYourOwnUserAssignedIdentityToSubscription\')]'
      }
      userAssignedIdentityResourceId: {
        value: '[parameters(\'userAssignedIdentityResourceId\')]'
      }
      userAssignedManagedIdentityName: {
        value: '[parameters(\'userAssignedManagedIdentityName\')]'
      }
      userAssignedManagedIdentityResourceGroup: {
        value: '[parameters(\'userAssignedManagedIdentityResourceGroup\')]'
      }
      scopeToSupportedImages: {
        value: '[parameters(\'scopeToSupportedImages\')]'
      }
      listOfWindowsImageIdToInclude: {
        value: '[parameters(\'listOfWindowsImageIdToInclude\')]'
      }
      enableExclusionTags: {
        value: '[parameters(\'enableExclusionTags\')]'
      }
    }
    groupNames: [
      'Monitoring'
    ]
  }
  {
    policyDefinitionReferenceId: 'AssociateDataCollectionRule'
    policyDefinitionId: customPolicies.outputs.dcrPolicyId
    parameters: {
      effect: {
        value: '[parameters(\'effect\')]'
      }
      dcrResourceId: {
        value: '[parameters(\'dcrResourceId\')]'
      }
      resourceType: {
        value: '[parameters(\'resourceType\')]'
      }
      scopeToSupportedImages: {
        value: '[parameters(\'scopeToSupportedImages\')]'
      }
      listOfWindowsImageIdToInclude: {
        value: '[parameters(\'listOfWindowsImageIdToInclude\')]'
      }
      enableExclusionTags: {
        value: '[parameters(\'enableExclusionTags\')]'
      }
    }
    groupNames: [
      'DataCollection'
    ]
  }
]

module customPolicies 'modules/policy.bicep' = {
  name: 'custom-policies-deployment'
  params: {
    environmentName: environmentName
    projectName: projectName
    deployGuestConfigPolicy: true
    amaPolicy: assignAMAPolicy
    uamiPolicy: assignUAMIPolicy
    dcrPolicy: assignDCRPolicy
    guestConfigPolicy: assignGuestConfigPolicy
  }
}

module customPolicySet 'modules/policySetDefinition.bicep' = {
  name: 'custom-policy-set-deployment'
  params: {
    policySetName: 'policyset-${projectName}-deployAMA-custom-set-${environmentName}'
    displayName: basePolicySetContent.properties.displayName
    policySetDescription: basePolicySetContent.properties.description
    metadata: basePolicySetContent.properties.metadata
    initiativeParameters: basePolicySetContent.properties.parameters
    policyDefinitionGroups: basePolicySetContent.properties.policyDefinitionGroups
    policyDefinitions: amaPolicyDefinitions
  }
}

module policySetAssignment 'modules/policyAssignment.bicep' = {
  name: 'policy-set-assignment-deployment'
  params: {
    environmentName: environmentName
    projectName: projectName
    policyDefinitionId: customPolicySet.outputs.policySetId
    assignmentName: 'AmaCustomSet'
    assignmentDisplayName: 'Deploy Azure Monitor Agent Complete Initiative - ${environmentName}'
    assignmentDescription: 'Assignment of the AMA Complete Deployment Initiative for comprehensive VM monitoring setup'
    userAssignedId: uamiVmAma.outputs.id
    dataCollectionRuleId: performanceDataCollectionRule.outputs.id
    identityType: 'UserAssigned'
    enforcementMode: 'Default'
    createRemediationTask: true
    policyDefinitionReferenceIds: [
      'AssignUserAssignedManagedIdentity'
      'DeployAzureMonitorAgent'
      'AssociateDataCollectionRule'
    ]
    location: location
  }
}

// ============================================================================
// GUEST CONFIGURATION POLICY ASSIGNMENT
// ============================================================================

module guestConfigPolicyAssignment 'modules/builtinPolicyAssignment.bicep' = {
  scope: subscription(subscriptionId)
  name: 'guest-config-policy-assignment'
  params: {
    assignmentName: 'assign-${projectName}-guest-config-${environmentName}'
    assignmentDisplayName: 'Assign Guest Configuration to Windows VMs - ${environmentName}'
    assignmentDescription: 'Deploys Guest Configuration package to Windows VMs for configuration management'
    policyDefinitionId: customPolicies.outputs.guestConfigPolicyId
    policyParameters: {
      effect: {
        value: 'DeployIfNotExists'
      }
      guestConfigurationName: {
        value: guestConfigurationName
      }
      guestConfigurationVersion: {
        value: guestConfigurationVersion
      }
      guestConfigurationContentUri: {
        value: guestConfigurationContentUri
      }
      guestConfigurationContentHash: {
        value: guestConfigurationContentHash
      }
      contentManagedIdentityResourceId: {
        value: uamiGuestConfig.outputs.id
      }
      inclusionTagName: {
        value: guestConfigTagName
      }
      inclusionTagValues: {
        value: guestConfigTagValues
      }
    }
    identityType: 'SystemAssigned'
    location: location
  }
}

// ============================================================================
// BUILT-IN POLICY ASSIGNMENTS
// ============================================================================

module backupPolicyAssignment 'modules/builtinPolicyAssignment.bicep' = {
  scope: subscription(subscriptionId)
  name: 'backup-policy-assignment-deployment'
  params: {
    assignmentName: 'assign-${projectName}-vm-backup-${environmentName}'
    assignmentDisplayName: 'Configure VM Backup for Tagged VMs - ${environmentName}'
    assignmentDescription: 'Configures backup on VMs with tag Backup:Standard to the central Recovery Services vault'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/345fa903-145c-4fe1-8bcd-93ec2adccde8'
    policyParameters: {
      vaultLocation: {
        value: location
      }
      inclusionTagName: {
        value: backupTagName
      }
      inclusionTagValue: {
        value: backupTagValues
      }
      backupPolicyId: {
        value: vmBackupPolicy.outputs.policyId
      }
      effect: {
        value: 'DeployIfNotExists'
      }
    }
    identityType: 'SystemAssigned'
    location: location
  }
}

module periodicAssessmentPolicyAssignment 'modules/builtinPolicyAssignment.bicep' = {
  scope: subscription(subscriptionId)
  name: 'periodic-assessment-policy-assignment-deployment'
  params: {
    assignmentName: 'assign-${projectName}-periodic-assessment-${environmentName}'
    assignmentDisplayName: 'Configure Periodic Assessment for all Windows VMs - ${environmentName}'
    assignmentDescription: 'Configures periodic assessment on VMs with tag Patch:Monthly/Weekly/Daily'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/59efceea-0c96-497e-a4a1-4eb2290dac15'
    identityType: 'SystemAssigned'
    location: location
  }
}
