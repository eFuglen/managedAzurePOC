// Built-in Policy Assignment Module
// For assigning Azure built-in policies at subscription scope
targetScope = 'subscription'

param assignmentName string
param assignmentDisplayName string
param assignmentDescription string = ''
param policyDefinitionId string
param policyParameters object = {}
param identityType string = 'SystemAssigned'
param enforcementMode string = 'Default'
param location string

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2023-04-01' = {
  name: assignmentName
  location: location
  identity: identityType == 'SystemAssigned' ? {
    type: 'SystemAssigned'
  } : null
  properties: {
    displayName: assignmentDisplayName
    description: !empty(assignmentDescription) ? assignmentDescription : 'Policy assignment for ${assignmentName}'
    policyDefinitionId: policyDefinitionId
    parameters: policyParameters
    enforcementMode: enforcementMode
  }
}

output assignmentId string = policyAssignment.id
output assignmentName string = policyAssignment.name
output principalId string = identityType == 'SystemAssigned' ? policyAssignment.identity.principalId : ''
