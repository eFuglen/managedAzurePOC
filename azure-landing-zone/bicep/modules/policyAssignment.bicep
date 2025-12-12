targetScope = 'managementGroup'

@description('Environment name (dev, test, prod)')
param environmentName string

@description('Project name used for resource naming')
param projectName string

@description('Policy or Policy Set definition ID to assign')
param policyDefinitionId string

@description('Assignment name (will be prefixed with assign-{projectName}-)')
param assignmentName string

@description('Assignment display name (optional, defaults to assignmentName)')
param assignmentDisplayName string = ''

@description('Assignment description')
param assignmentDescription string = ''

@description('Policy assignment parameters')
param policyAssignmentParams object = {}

@description('User-Assigned Managed Identity resource ID (required for UserAssigned identity type)')
param userAssignedId string = ''

@description('Data Collection Rule resource ID (for AMA policies)')
param dataCollectionRuleId string = ''

@description('Identity type for the policy assignment')
@allowed([
  'SystemAssigned'
  'UserAssigned'
  'None'
])
param identityType string = 'UserAssigned'

@description('Assignment enforcement mode')
@allowed([
  'Default'
  'DoNotEnforce'
])
param enforcementMode string = 'Default'

@description('Whether to create automatic remediation task')
param createRemediationTask bool = true

@description('Policy definition reference IDs for policy set remediation (array of reference IDs from the policy set)')
param policyDefinitionReferenceIds array = []

@description('Assignment location for metadata (required for subscription scope)')
param location string = 'eastus'

var validateUserAssignedId = (identityType == 'UserAssigned' && empty(userAssignedId)) 
  ? 'The parameter "userAssignedId" is required when "identityType" is set to "UserAssigned".' 
  : ''

var fullAssignmentName = '${projectName}-${assignmentName}-${environmentName}'

var finalDisplayName = empty(assignmentDisplayName) ? assignmentName : assignmentDisplayName

var isPolicySet = contains(policyDefinitionId, '/policySetDefinitions/')

var shouldCreateRemediation = createRemediationTask && identityType != 'None' && (!isPolicySet || length(policyDefinitionReferenceIds) > 0)

var amaDefaultParameters = (!empty(dataCollectionRuleId) && !empty(userAssignedId)) ? {
  effect: {
    value: 'DeployIfNotExists'
  }
  enableExclusionTags: {
    value: true
  }
  bringYourOwnUserAssignedManagedIdentity: {
    value: true
  }
  restrictBringYourOwnUserAssignedIdentityToSubscription: {
    value: true
  }
  userAssignedManagedIdentityName: {
    value: split(userAssignedId, '/')[8] // Extract name from resource ID
  }
  userAssignedManagedIdentityResourceGroup: {
    value: split(userAssignedId, '/')[4] // Extract RG from resource ID
  }
  userAssignedIdentityResourceId: {
    value: userAssignedId
  }
  dcrResourceId: {
    value: dataCollectionRuleId
  }
  resourceType: {
    value: 'Microsoft.Insights/dataCollectionRules'
  }
  scopeToSupportedImages: {
    value: true
  }
  listOfWindowsImageIdToInclude: {
    value: []
  }
  builtInIdentityResourceGroupLocation: {
    value: location
  }
} : {}

var finalParameters = union(amaDefaultParameters, policyAssignmentParams)


var identityObject = identityType == 'SystemAssigned' 
  ? { type: 'SystemAssigned' } 
  : identityType == 'UserAssigned'
  ? { 
      type: 'UserAssigned' 
      userAssignedIdentities: {
        '${userAssignedId}': {}
      }
    }
  : null


resource policyAssignment 'Microsoft.Authorization/policyAssignments@2023-04-01' = {
  name: fullAssignmentName
  location: location
  identity: identityObject
  
  properties: {
    displayName: finalDisplayName
    description: empty(assignmentDescription) ? 'Policy assignment for ${assignmentName} in ${environmentName} environment' : assignmentDescription
    policyDefinitionId: policyDefinitionId
    parameters: finalParameters
    enforcementMode: enforcementMode
  }
}

resource remediateTask 'Microsoft.PolicyInsights/remediations@2021-10-01' = [for (refId, index) in (isPolicySet ? policyDefinitionReferenceIds : ['']) : if (shouldCreateRemediation) {
  name: 'remediate-${take(fullAssignmentName, 50)}-${take(uniqueString(policyDefinitionId, refId), 8)}'
  properties: {
    failureThreshold: {
      percentage: 1
    }
    resourceCount: 1000
    policyAssignmentId: policyAssignment.id
    policyDefinitionReferenceId: refId
    parallelDeployments: 10
    resourceDiscoveryMode: 'ExistingNonCompliant'
  }
}]

var remediationTaskIdsForPolicySet = [for (refId, index) in policyDefinitionReferenceIds : remediateTask[index].id]
var remediationTaskIdsForSinglePolicy = shouldCreateRemediation && !isPolicySet ? [remediateTask[0].id] : []
var remediationTaskIds = isPolicySet ? remediationTaskIdsForPolicySet : remediationTaskIdsForSinglePolicy

output assignmentId string = policyAssignment.id
output assignmentName string = policyAssignment.name
output assignmentDisplayName string = policyAssignment.properties.displayName
output principalId string = (identityType == 'SystemAssigned' && policyAssignment.identity != null) ? policyAssignment.identity.principalId : ''
output remediationTaskIds array = remediationTaskIds
output remediationTaskCount int = shouldCreateRemediation ? (isPolicySet ? length(policyDefinitionReferenceIds) : 1) : 0
output isPolicySet bool = isPolicySet
output validationError string = validateUserAssignedId
