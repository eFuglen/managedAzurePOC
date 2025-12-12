// Custom Policy Deployment Module for Azure Landing Zone
// Deploys all three custom policy definitions

targetScope = 'managementGroup'

@description('Environment name (dev, test, prod)')
param environmentName string

@description('Project name used for resource naming')
param projectName string

@description('Deploy guest configuration policy')
param deployGuestConfigPolicy bool = false

@description('Policy definition object for AMA')
param amaPolicy object

@description('Policy definition object for UAMI')
param uamiPolicy object

@description('Policy definition object for DCR association')
param dcrPolicy object

@description('Policy definition object for Guest Configuration (optional)')
param guestConfigPolicy object = {}

// Deploy Azure Monitor Agent Policy
resource amaPolicyDef 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: 'policy-${projectName}-assignAMA-vm-${environmentName}'
  properties: {
    displayName: amaPolicy.properties.displayName
    description: amaPolicy.properties.description
    policyType: amaPolicy.properties.policyType
    mode: amaPolicy.properties.mode
    metadata: amaPolicy.properties.metadata
    parameters: amaPolicy.properties.parameters
    policyRule: amaPolicy.properties.policyRule
  }
}

// Deploy User-Assigned Managed Identity Policy
resource uamiPolicyDef 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: 'policy-${projectName}-assignUAMI-vm-${environmentName}'
  properties: {
    displayName: uamiPolicy.properties.displayName
    description: uamiPolicy.properties.description
    policyType: uamiPolicy.properties.policyType
    mode: uamiPolicy.properties.mode
    metadata: uamiPolicy.properties.metadata
    parameters: uamiPolicy.properties.parameters
    policyRule: uamiPolicy.properties.policyRule
  }
}

// Deploy Data Collection Rule Policy
resource dcrPolicyDef 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: 'policy-${projectName}-assignDCR-vm-${environmentName}'
  properties: {
    displayName: dcrPolicy.properties.displayName
    description: dcrPolicy.properties.description
    policyType: dcrPolicy.properties.policyType
    mode: dcrPolicy.properties.mode
    metadata: dcrPolicy.properties.metadata
    parameters: dcrPolicy.properties.parameters
    policyRule: dcrPolicy.properties.policyRule
  }
}

// Deploy Guest Configuration Policy
resource guestConfigPolicyDef 'Microsoft.Authorization/policyDefinitions@2023-04-01' = if (deployGuestConfigPolicy) {
  name: 'policy-${projectName}-assign-guest-config-${environmentName}'
  properties: {
    displayName: guestConfigPolicy.properties.displayName
    description: guestConfigPolicy.properties.description
    policyType: guestConfigPolicy.properties.policyType
    mode: guestConfigPolicy.properties.mode
    metadata: guestConfigPolicy.properties.metadata
    parameters: guestConfigPolicy.properties.parameters
    policyRule: guestConfigPolicy.properties.policyRule
  }
}

// Outputs
output amaPolicyId string = amaPolicyDef.id
output amaPolicyName string = amaPolicyDef.name
output uamiPolicyId string = uamiPolicyDef.id
output uamiPolicyName string = uamiPolicyDef.name
output dcrPolicyId string = dcrPolicyDef.id
output dcrPolicyName string = dcrPolicyDef.name
output guestConfigPolicyId string = deployGuestConfigPolicy ? guestConfigPolicyDef.id : ''
output guestConfigPolicyName string = deployGuestConfigPolicy ? guestConfigPolicyDef.name : ''
