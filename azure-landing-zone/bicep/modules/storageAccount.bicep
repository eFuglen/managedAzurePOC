@description('Storage account name.')
@minLength(3)
@maxLength(24)
param name string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('SKU.')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Standard_RAGRS'
])
param sku string = 'Standard_LRS'

@description('Kind.')
@allowed([
  'StorageV2'
  'BlobStorage'
  'FileStorage'
])
param kind string = 'StorageV2'

@description('Access tier.')
@allowed([
  'Hot'
  'Cool'
])
param accessTier string = 'Hot'

@description('TLS minimum version.')
@allowed([
  'TLS1_0'
  'TLS1_1'
  'TLS1_2'
])
param minTls string = 'TLS1_2'

@description('Allow only HTTPS.')
param httpsOnly bool = true

@description('Allow blob public access.')
param allowBlobPublicAccess bool = false

@description('Hierarchical namespace.')
param enableHns bool = false

@description('Blob soft delete days.')
@minValue(1)
@maxValue(365)
param blobSoftDeleteDays int = 7

@description('Container soft delete days.')
@minValue(1)
@maxValue(365)
param containerSoftDeleteDays int = 7

@description('Tags.')
param tags object = {}

resource sa 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: kind
  properties: {
    accessTier: accessTier
    minimumTlsVersion: minTls
    supportsHttpsTrafficOnly: httpsOnly
    allowBlobPublicAccess: allowBlobPublicAccess
    isHnsEnabled: enableHns
  }
}

resource blob 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  name: 'default'
  parent: sa
  properties: {
    deleteRetentionPolicy: {
      enabled: blobSoftDeleteDays > 0
      days: blobSoftDeleteDays
    }
    containerDeleteRetentionPolicy: {
      enabled: containerSoftDeleteDays > 0
      days: containerSoftDeleteDays
    }
  }
}
