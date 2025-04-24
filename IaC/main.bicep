targetScope = 'subscription'

// Parameters
@description('A short name for the workload being deployed alphanumberic only')
@maxLength(8)
param workloadName string

@description('The environment for which the deployment is being executed')
@allowed([
  'dev'
  'uat'
  'prod'
  'dr'
])
param environment string

param identifier string


param location string = deployment().location

// @description('Enable sending usage and telemetry feedback to Microsoft.')
// param enableTelemetry bool = true
// var telemetryId = 'ab1e5729-7452-41b2-9fbb-945cc51d9cd0-${location}-apimsb-main'

// Variables
var resourceSuffix = '${workloadName}-${environment}-${location}-${identifier}'
var resourceGroupName = 'RG-Servicios_DEVL_APIM'


// Resource Names
var apimName = 'apim-${resourceSuffix}'


resource rG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}


module networking './networking/networking.bicep' = {
  name: 'networkingresources'
  scope: resourceGroup(rG.name)
  params: {
    location: location
    resourceSuffix: resourceSuffix
  }
}

module shared './shared/shared.bicep' = {
  dependsOn: [
    networking
  ]
  name: 'sharedresources'
  scope: resourceGroup(rG.name)
  params: {
    workloadName: workloadName
    environment: environment
    identifier: identifier
    location: location
    resourceGroupName: rG.name
    resourceSuffix: resourceSuffix
    vnetName: networking.outputs.apimCSVNetName
    privateEndpointSubnetid: networking.outputs.privateEndpointSubnetid
    networkingResourceGroupName: rG.name    
  }
}

module apimModule 'apim/apim.bicep' = {
  name: 'apimDeploy'
  scope: resourceGroup(rG.name)
  params: {
    apimName: apimName
    apimSubnetId: networking.outputs.apimSubnetid
    location: location
    appInsightsName: shared.outputs.appInsightsName
    appInsightsId: shared.outputs.appInsightsId
    appInsightsInstrumentationKey: shared.outputs.appInsightsInstrumentationKey
    keyVaultName: shared.outputs.keyVaultName
    keyVaultResourceGroupName: rG.name
    networkingResourceGroupName: rG.name
    apimRG: rG.name
    vnetName: networking.outputs.apimCSVNetName
  }
}


output resourceSuffix string = resourceSuffix
output resourceGroupName string = resourceGroupName
output apimName string = apimName
output apimIdentityName string = apimModule.outputs.apimIdentityName
output vnetId string = networking.outputs.apimCSVNetId
output vnetName string = networking.outputs.apimCSVNetName
output privateEndpointSubnetid string = networking.outputs.privateEndpointSubnetid
output keyVaultName string = shared.outputs.keyVaultName
output apimStarterSubscriptionKey string = apimModule.outputs.apimStarterSubscriptionKey
