// =============================================================================
// Lab 20 - main.bicep (starter)
//
// Nusantara Retail's storefront basics, described once instead of clicked.
// The parameters, the variables and the storage account are done. You add:
//   EXERCISE 1  nsg-web             network security group: HTTP (TCP 80) in from the internet
//   EXERCISE 2  vnet-nusa-iac       virtual network with snet-web (uses nsg-web) and snet-app
//   EXERCISE 3  log-nusa-<suffix>   Log Analytics workspace
//   EXERCISE 4  three more outputs
//
// This file builds as it is. Build again after every exercise to catch mistakes early:
//   az bicep build --file main.bicep
// =============================================================================

targetScope = 'resourceGroup'

// ---------- Parameters -------------------------------------------------------

@description('Azure region for every resource. The default is the region of the resource group.')
param location string = resourceGroup().location

@description('Lowercase letters and digits that make global names unique. The default is the same on every deployment to this resource group.')
@minLength(3)
@maxLength(13)
param suffix string = uniqueString(resourceGroup().id)

@description('The environment this copy is for. It is added to the tags of every resource.')
@allowed([
  'lab'
  'test'
  'prod'
])
param environment string = 'lab'

@description('Tags for every resource. The environment tag is added automatically.')
param tags object = {
  costCenter: 'retail-lab'
  workload: 'storefront'
  managedBy: 'bicep'
}

// ---------- Variables --------------------------------------------------------

var allTags = union(tags, {
  environment: environment
})

// Storage account names: 3-24 characters, lowercase letters and digits only, unique across Azure.
var storageAccountName = toLower('stiac${suffix}')

// ---------- Storage account --------------------------------------------------
// A finished example: use it as a pattern for the exercises below.

resource storage 'Microsoft.Storage/storageAccounts@2025-01-01' = {
  name: storageAccountName
  location: location
  tags: allTags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
  }
}

// =============================================================================
// EXERCISE 1 - Network security group for the web subnet
// -----------------------------------------------------------------------------
// Add a resource with the symbolic name nsgWeb:
//   type@API version   Microsoft.Network/networkSecurityGroups@2024-05-01
//   name               'nsg-web'
//   location, tags     location and allTags, like the storage account
//   properties         securityRules: an array with one rule, an object with
//                      name 'Allow-HTTP-From-Internet' and its own properties:
//                        priority 100, direction 'Inbound', access 'Allow',
//                        protocol 'Tcp', sourceAddressPrefix 'Internet',
//                        sourcePortRange '*', destinationAddressPrefix '*',
//                        destinationPortRange '80'
// =============================================================================


// =============================================================================
// EXERCISE 2 - Virtual network with two subnets
// -----------------------------------------------------------------------------
// Add a resource with the symbolic name vnet:
//   type@API version   Microsoft.Network/virtualNetworks@2024-05-01
//   name               'vnet-nusa-iac'
//   location, tags     location and allTags
//   properties         addressSpace.addressPrefixes: ['10.20.0.0/16']
//                      subnets: an array with two objects (define them here, inside
//                      the virtual network, not as separate resources):
//                        snet-web  addressPrefix '10.20.1.0/24',
//                                  defaultOutboundAccess false and
//                                  networkSecurityGroup: { id: nsgWeb.id }
//                        snet-app  addressPrefix '10.20.2.0/24',
//                                  defaultOutboundAccess false
// Referring to nsgWeb.id is all Bicep needs to deploy the NSG first.
// defaultOutboundAccess false makes the subnets private: no default outbound internet access.
// =============================================================================


// =============================================================================
// EXERCISE 3 - Log Analytics workspace
// -----------------------------------------------------------------------------
// Add a resource with the symbolic name logs:
//   type@API version   Microsoft.OperationalInsights/workspaces@2023-09-01
//   name               'log-nusa-${suffix}'
//   location, tags     location and allTags
//   properties         sku.name 'PerGB2018' and retentionInDays 30
// =============================================================================


// ---------- Outputs ----------------------------------------------------------

output storageAccountName string = storage.name
output storageBlobEndpoint string = storage.properties.primaryEndpoints.blob

// =============================================================================
// EXERCISE 4 - More outputs
// -----------------------------------------------------------------------------
// Add three string outputs:
//   vnetId                    the ID of the virtual network     vnet.id
//   webSubnetId               the ID of snet-web (subnet 0)     vnet.properties.subnets[0].id
//   logAnalyticsWorkspaceId   the ID of the workspace           logs.id
// =============================================================================
