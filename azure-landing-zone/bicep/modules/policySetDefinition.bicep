// Generic Policy Set (Initiative) Module
// Builds a policy set from caller-supplied properties (display name, description, metadata, initiative parameters, policy definitions, and groups)

targetScope = 'managementGroup'

@description('Unique name of the policy set (initiative)')
param policySetName string

@description('Display name of the policy set')
param displayName string

@description('Description of the policy set')
param policySetDescription string

@description('Metadata object for the policy set')
param metadata object = {}

@description('Initiative-level parameters (definition-time parameters)')
param initiativeParameters object = {}

@description('Policy definitions included in the policy set')
param policyDefinitions array

@description('Optional policy definition groups')
param policyDefinitionGroups array = []

resource customPolicySet 'Microsoft.Authorization/policySetDefinitions@2023-04-01' = {
  name: policySetName
  properties: {
    displayName: displayName
    description: policySetDescription
    metadata: metadata
    parameters: initiativeParameters
    policyDefinitions: policyDefinitions
    policyDefinitionGroups: policyDefinitionGroups
  }
}

// Outputs
output policySetId string = customPolicySet.id
output policySetName string = customPolicySet.name
output policySetDisplayName string = displayName
output policyReferences array = customPolicySet.properties.policyDefinitions
