param apimCSVNetNameAddressPrefix string = '10.0.0.0/16'

param apimAddressPrefix string = '10.0.1.0/27' // Ajustado para estar dentro del rango de la red virtual
param privateEndpointAddressPrefix string = '10.0.2.0/27'


param location string

@description('Standardized suffix text to be added to resource names')
param resourceSuffix string

// Variables
var owner = 'APIM Const Set'

var apimCSVNetName = 'vnet-apim-cs-${resourceSuffix}'

var apimSubnetName = 'snet-apim-${resourceSuffix}'
var apimSNNSG = 'nsg-apim-${resourceSuffix}'

var privateEndpointSubnetName = 'snet-prep-${resourceSuffix}'
var privateEndpointSNNSG = 'nsg-prep-${resourceSuffix}'


// Resources - VNet - SubNets
resource vnetApimCs 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: apimCSVNetName
  location: location
  tags: {
    Owner: owner
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        apimCSVNetNameAddressPrefix
      ]
    }
    enableVmProtection: false
    enableDdosProtection: false
    subnets: [      
      {
        name: apimSubnetName
        properties: {
          addressPrefix: apimAddressPrefix
          networkSecurityGroup: {
            id: apimNSG.id
          }
        }
      }
      {
        name: privateEndpointSubnetName
        properties: {
          addressPrefix: privateEndpointAddressPrefix
          networkSecurityGroup: {
            id: privateEndpointNSG.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }      
    ]
  }
}

// Network Security Groups (NSG)

resource apimNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: apimSNNSG
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowApimManagement'
        properties: {
          priority: 2000
          sourceAddressPrefix: 'ApiManagement'
          protocol: 'Tcp'
          destinationPortRange: '3443'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'AllowAzureLoadBalancer'
        properties: {
          priority: 2010
          sourceAddressPrefix: 'AzureLoadBalancer'
          protocol: 'Tcp'
          destinationPortRange: '6390'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'AllowAzureTrafficManager'
        properties: {
          priority: 2020
          sourceAddressPrefix: 'AzureTrafficManager'
          protocol: 'Tcp'
          destinationPortRange: '443'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'AllowStorage'
        properties: {
          priority: 2000
          sourceAddressPrefix: 'VirtualNetwork'
          protocol: 'Tcp'
          destinationPortRange: '443'
          access: 'Allow'
          direction: 'Outbound'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Storage'
        }
      }
      {
        name: 'AllowSql'
        properties: {
          priority: 2010
          sourceAddressPrefix: 'VirtualNetwork'
          protocol: 'Tcp'
          destinationPortRange: '1433'
          access: 'Allow'
          direction: 'Outbound'
          sourcePortRange: '*'
          destinationAddressPrefix: 'SQL'
        }
      }
      {
        name: 'AllowKeyVault'
        properties: {
          priority: 2020
          sourceAddressPrefix: 'VirtualNetwork'
          protocol: 'Tcp'
          destinationPortRange: '443'
          access: 'Allow'
          direction: 'Outbound'
          sourcePortRange: '*'
          destinationAddressPrefix: 'AzureKeyVault'
        }
      }
      {
        name: 'AllowMonitor'
        properties: {
          priority: 2030
          sourceAddressPrefix: 'VirtualNetwork'
          protocol: 'Tcp'
          destinationPortRanges: ['1886', '443']
          access: 'Allow'
          direction: 'Outbound'
          sourcePortRange: '*'
          destinationAddressPrefix: 'AzureMonitor'
        }
      }
    ]
  }
}

resource privateEndpointNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: privateEndpointSNNSG
  location: location
  properties: {
    securityRules: []
  }
}


// Output section
output apimCSVNetName string = apimCSVNetName
output apimCSVNetId string = vnetApimCs.id

output apimSubnetName string = apimSubnetName
output privateEndpointSubnetName string = privateEndpointSubnetName

output apimSubnetid string = '${vnetApimCs.id}/subnets/${apimSubnetName}'
output privateEndpointSubnetid string = '${vnetApimCs.id}/subnets/${privateEndpointSubnetName}'


