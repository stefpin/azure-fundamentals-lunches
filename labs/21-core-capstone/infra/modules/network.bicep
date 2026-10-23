// =============================================================================
// Network for the storefront: one virtual network, two PRIVATE subnets
// (no default outbound access) and a network security group for each.
// Pairs with Lunch 08 (address planning, subnets, NSGs, service tags).
// =============================================================================

@description('Azure region.')
param location string

@description('Tags for every resource.')
param tags object

@description('Address space of the virtual network. It must not overlap head office (10.0.0.0/16).')
param addressPrefix string = '10.21.0.0/16'

@description('Subnet for the web servers.')
param webSubnetPrefix string = '10.21.1.0/24'

@description('Subnet kept free for private endpoints (deep-dive month: Lunches 24, 25 and 28).')
param dataSubnetPrefix string = '10.21.2.0/24'

// NSG for the web subnet. Only HTTP gets in: from shoppers (Internet) and from the
// load balancer's health probe (AzureLoadBalancer = 168.63.129.16). SSH stays closed;
// you manage the VMs with Run Command instead.
resource nsgWeb 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-web'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTP-Internet'
        properties: {
          description: 'Shoppers reach the storefront on port 80 through the load balancer.'
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '80'
        }
      }
      {
        name: 'Allow-HTTP-AzureLoadBalancer'
        properties: {
          description: 'Load balancer health probes reach /health on port 80.'
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '80'
        }
      }
    ]
  }
}

// NSG for the data subnet: no custom rules, so the default rules deny inbound internet traffic.
resource nsgData 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-data'
  location: location
  tags: tags
  properties: {
    securityRules: []
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-nusa-capstone'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: 'snet-web'
        properties: {
          addressPrefix: webSubnetPrefix
          networkSecurityGroup: {
            id: nsgWeb.id
          }
          // Private subnet: VMs get no implicit internet access. They go out through the
          // load balancer's outbound rule instead (see web.bicep).
          defaultOutboundAccess: false
        }
      }
      {
        name: 'snet-data'
        properties: {
          addressPrefix: dataSubnetPrefix
          networkSecurityGroup: {
            id: nsgData.id
          }
          defaultOutboundAccess: false
        }
      }
    ]
  }
}

resource webSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: vnet
  name: 'snet-web'
}

output vnetName string = vnet.name
output webSubnetId string = webSubnet.id
