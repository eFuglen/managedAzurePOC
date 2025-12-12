param name string
param sku object = {
  name: 'RS0'
  tier: 'Standard'
}
@allowed([
  'Enabled'
  'Disabled'
])
param crossRegionRestore string = 'Enabled'
@allowed([
  'GeoRedundant'
  'LocallyRedundant'
  'ZoneRedundant'
  'GeoZoneRedundant'
])
param vaultStorageType string = 'GeoRedundant'
@allowed([
  'Enabled'
  'Disabled'
])
param softDeleteFeatureState string = 'Disabled'
@allowed([
  'AlwaysON'
  'Disabled'
  'Enabled'
  'Invalid'
])
param enhancedSecurityState string = 'Disabled'

param softDeleteRetentionPeriodInDays int = 14

param location string = resourceGroup().location
param tags object

resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2025-02-01' = {
  name: 'rsv-${name}'
  location: location
  tags: tags
  sku: sku
  properties: {
    publicNetworkAccess: 'Enabled'
    redundancySettings: {
      crossRegionRestore: crossRegionRestore
      standardTierStorageRedundancy: vaultStorageType
    }
    securitySettings: {
      softDeleteSettings: {
        enhancedSecurityState: enhancedSecurityState
        softDeleteState: softDeleteFeatureState
        softDeleteRetentionPeriodInDays: softDeleteRetentionPeriodInDays
      }
    }
  }
}

// Outputs
@description('Recovery Services Vault resource ID')
output id string = recoveryServicesVault.id

@description('Recovery Services Vault name')
output name string = recoveryServicesVault.name
