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
var networkingResourceGroupName = 'rg-networking-${resourceSuffix}'
var sharedResourceGroupName = 'rg-shared-${resourceSuffix}'
var apimResourceGroupName = 'rg-apim-${resourceSuffix}'

// Resource Names
var apimName = 'apim-${resourceSuffix}'
var appGatewayName = 'appgw-${resourceSuffix}'

resource networkingRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: networkingResourceGroupName
  location: location
}

resource sharedRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: sharedResourceGroupName
  location: location
}

resource apimRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: apimResourceGroupName
  location: location
}

module networking './networking/networking.bicep' = {
  name: 'networkingresources'
  scope: resourceGroup(networkingRG.name)
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
  scope: resourceGroup(sharedRG.name)
  params: {
    workloadName: workloadName
    environment: environment
    identifier: identifier
    location: location
    resourceGroupName: sharedRG.name
    resourceSuffix: resourceSuffix
    vnetName: networking.outputs.apimCSVNetName
    privateEndpointSubnetid: networking.outputs.privateEndpointSubnetid
    networkingResourceGroupName: networkingRG.name    
  }
}

module apimModule 'apim/apim.bicep' = {
  name: 'apimDeploy'
  scope: resourceGroup(apimRG.name)
  params: {
    apimName: apimName
    apimSubnetId: networking.outputs.apimSubnetid
    location: location
    appInsightsName: shared.outputs.appInsightsName
    appInsightsId: shared.outputs.appInsightsId
    appInsightsInstrumentationKey: shared.outputs.appInsightsInstrumentationKey
    keyVaultName: shared.outputs.keyVaultName
    keyVaultResourceGroupName: sharedRG.name
    networkingResourceGroupName: networkingRG.name
    apimRG: apimRG.name
    vnetName: networking.outputs.apimCSVNetName
  }
}


output resourceSuffix string = resourceSuffix
output networkingResourceGroupName string = networkingResourceGroupName
output sharedResourceGroupName string = sharedResourceGroupName
output apimResourceGroupName string = apimResourceGroupName
output apimName string = apimName
output apimIdentityName string = apimModule.outputs.apimIdentityName
output vnetId string = networking.outputs.apimCSVNetId
output vnetName string = networking.outputs.apimCSVNetName
output privateEndpointSubnetid string = networking.outputs.privateEndpointSubnetid
output keyVaultName string = shared.outputs.keyVaultName
output appGatewayName string = appGatewayName
output apimStarterSubscriptionKey string = apimModule.outputs.apimStarterSubscriptionKey


// // Variables
// param location string
// param resourceGroupName string
// param vnetName string
// param subnetIntAPIMName string
// param subnetPrivEndAPIMName string
// param nsgIntAPIMName string
// param nsgPrivEndAPIMName string
// param apimName string
// param keyVaultName string
// param redisName string
// param appInsightsName string
// param skuName string
// param publisherEmail string
// param publisherName string


// // Virtual Network
// resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
//   name: vnetName
//   location: location
//   properties: {
//     addressSpace: {
//       addressPrefixes: ['10.0.0.0/16'] // Rango de direcciones de la red virtual
//     }
//     subnets: [
//       {
//         name: subnetIntAPIMName
//         properties: {
//           addressPrefix: '10.0.1.0/27' // Rango de direcciones para la subred IntAPIM
//         }
//       }
//       {
//         name: subnetPrivEndAPIMName
//         properties: {
//           addressPrefix: '10.0.2.0/27' // Rango de direcciones para la subred PrivEndAPIM
//         }
//       }
//     ]
//   }
// }

// // Network Security Group for SubNet-IntAPIM
// resource nsgIntAPIM 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
//   name: nsgIntAPIMName
//   location: location
//   properties: {
//     securityRules: [
//       {
//         name: 'Allow-APIM-Inbound'
//         properties: {
//           priority: 400
//           direction: 'Inbound'
//           access: 'Allow'
//           protocol: '*'
//           sourcePortRange: '*'
//           destinationPortRange: '*'
//           sourceAddressPrefix: '*'
//           destinationAddressPrefix: '*'
//         }
//       }
//       {
//         name: 'Allow-APIM-Outbound'
//         properties: {
//           priority: 400
//           direction: 'Outbound'
//           access: 'Allow'
//           protocol: '*'
//           sourcePortRange: '*'
//           destinationPortRange: '*'
//           sourceAddressPrefix: '*'
//           destinationAddressPrefix: '*'
//         }
//       }
//     ]
//   }
// }

// // Network Security Group for SubNet-PrivEndAPIM
// resource nsgPrivEndAPIM 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
//   name: nsgPrivEndAPIMName
//   location: location
//   properties: {
//     securityRules: [
//       {
//         name: 'Allow-PrivateEndpoint-Inbound'
//         properties: {
//           priority: 400
//           direction: 'Inbound'
//           access: 'Allow'
//           protocol: '*'
//           sourcePortRange: '*'
//           destinationPortRange: '*'
//           sourceAddressPrefix: '*'
//           destinationAddressPrefix: '*'
//         }
//       }
//       {
//         name: 'Allow-PrivateEndpoint-Outbound'
//         properties: {
//           priority: 400
//           direction: 'Outbound'
//           access: 'Allow'
//           protocol: '*'
//           sourcePortRange: '*'
//           destinationPortRange: '*'
//           sourceAddressPrefix: '*'
//           destinationAddressPrefix: '*'
//         }
//       }
//     ]
//   }
// }

// // Asociar NSG con SubNet-IntAPIM
// resource subnetIntAPIMAssociation 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' = {
//   name: '${vnet.name}/${subnetIntAPIMName}'
//   properties: {
//     networkSecurityGroup: {
//       id: nsgIntAPIM.id
//     }
//   }
//   dependsOn: [vnet, nsgIntAPIM]
// }

// // Asociar NSG con SubNet-PrivEndAPIM
// resource subnetPrivEndAPIMAssociation 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' = {
//   name: '${vnet.name}/${subnetPrivEndAPIMName}'
//   properties: {
//     networkSecurityGroup: {
//       id: nsgPrivEndAPIM.id
//     }
//   }
//   dependsOn: [vnet, nsgPrivEndAPIM]
// }

// // API Management
// resource apim 'Microsoft.ApiManagement/service@2021-08-01' = {
//     name: apimName
//     location: location
//     identity: {
//         type: 'SystemAssigned'
//     }
//     sku: {
//         name: skuName
//         capacity: 1
//     }
//     properties: {
//         publisherEmail: publisherEmail
//         publisherName: publisherName
//         virtualNetworkType: 'Internal'
//         virtualNetworkConfiguration: {
//             subnetResourceId: vnet.properties.subnets[0].id
//         }
//     }
//     dependsOn: [vnet, subnetIntAPIMAssociation]
// }

// // Agregar configuración para integrar Azure Redis Cache con API Management
// resource apimRedis 'Microsoft.ApiManagement/service/caches@2021-08-01' = {
//     name: 'redis'
//     parent: apim
//     properties: {
//         connectionString: listKeys(redis.id, '2021-06-01').primaryKey
//         description: 'Integración de Redis Cache con API Management'
//         resourceId: redis.id
//     }
//     dependsOn: [apim, redis]
// }

// // Azure Key Vault with Private Endpoint
// resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
//     name: keyVaultName
//     location: location
//     properties: {
//         sku: {
//             family: 'A'
//             name: 'standard'
//         }
//         networkAcls: {
//             defaultAction: 'Deny'
//             bypass: 'AzureServices'
//             virtualNetworkRules: [
//                 {
//                     id: vnet.properties.subnets[0].id
//                 }
//             ]
//         }
//     }
//     dependsOn: [vnet]
// }

// // Private Endpoint for Key Vault
// resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
//     name: 'keyvault-private-endpoint'
//     location: location
//     properties: {
//         subnet: {
//             id: vnet.properties.subnets[1].id
//         }
//         privateLinkServiceConnections: [
//             {
//                 name: 'keyvaultConnection'
//                 properties: {
//                     privateLinkServiceId: keyVault.id
//                     groupIds: ['vault']
//                 }
//             }
//         ]
//     }
//     dependsOn: [keyVault,vnet]
// }

// // Ajustar la asignación de roles para evitar errores de cálculo al inicio del despliegue
// resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
//     name: guid(subscription().id, keyVault.id, 'KeyVaultSecretsUser')
//     properties: {
//         roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Rol: Key Vault Secrets User
//         principalId: apim.identity.principalId
//         principalType: 'ServicePrincipal'
//         scope: keyVault.id
//     }
//     dependsOn: [keyVault, apim]
// }

// // Azure Redis Cache
// resource redis 'Microsoft.Cache/Redis@2021-06-01' = {
//     name: redisName
//     location: location
//     sku: {
//         name: 'Standard'
//         family: 'C'
//         capacity: 1
//     }
//     properties: {
//         enableNonSslPort: false
//         minimumTlsVersion: '1.2'
//         subnetId: vnet.properties.subnets[0].id
//     }
//     dependsOn: [vnet]
// }

// // Private Endpoint for Redis
// resource redisPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
//     name: 'redis-private-endpoint'
//     location: location
//     properties: {
//         subnet: {
//             id: vnet.properties.subnets[1].id
//         }
//         privateLinkServiceConnections: [
//             {
//                 name: 'redisConnection'
//                 properties: {
//                     privateLinkServiceId: redis.id
//                     groupIds: ['RedisCache']
//                 }
//             }
//         ]
//     }
//     dependsOn: [redis]
// }

// // Application Insights
// resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
//   name: appInsightsName
//   location: location
//   properties: {
//     Application_Type: 'web'
//   }
// }

// // Eliminar la asignación de roles del archivo principal y moverla a un módulo independiente
// // Se debe realizar la asignación de roles después de que el recurso APIM esté creado.

// // Comentario: La asignación de roles debe realizarse manualmente o en un módulo separado.
