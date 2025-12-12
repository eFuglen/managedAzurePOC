targetScope = 'resourceGroup'

@description('The name of the resource group to assign the role to')
param resourceGroupName string

@description('The principal ID of the user or service principal to assign the role to')
param principalId string

@description('The name of the role to assign')
param roleDefinitionId string

@allowed([
  'ForeignGroup'
  'Group'
  'ServicePrincipal'
  'User'
])
param principalType string = 'ServicePrincipal'

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: roleDefinitionId
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroupName, principalId, roleDefinition.name)
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: principalId
    principalType: principalType
  }
}

output roleName string = roleDefinition.name
