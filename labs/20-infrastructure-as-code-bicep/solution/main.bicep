// =============================================================================
// Lab 20 - main.bicep (complete solution)
//
// Nusantara Retail's storefront basics, described once instead of clicked:
//   nsg-web             network security group: HTTP (TCP 80) in from the internet
//   vnet-nusa-iac       virtual network 10.20.0.0/16 with snet-web (uses nsg-web) and snet-app
//   stiac<suffix>       storage account: Standard_LRS, StorageV2, HTTPS only, TLS 1.2
//   log-nusa-<suffix>   Log Analytics workspace: pay per GB, 30 days retention
//
// Build:    az bicep build --file main.bicep
// Preview:  az deployment group what-if --resource-group <rg> --template-file main.bicep
// Deploy:   az deployment group create --resource-group <rg> --template-file main.bicep
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

// ---------- EXERCISE 1 - Network security group for the web subnet ----------

resource nsgWeb 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-web'
  location: location
  tags: allTags
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTP-From-Internet'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
        }
      }
    ]
  }
}

// ---------- EXERCISE 2 - Virtual network with two subnets --------------------

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-nusa-iac'
  location: location
  tags: allTags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.20.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'snet-web'
        properties: {
          addressPrefix: '10.20.1.0/24'
          defaultOutboundAccess: false // private subnet: no default outbound internet access
          networkSecurityGroup: {
            id: nsgWeb.id // symbolic reference: Bicep deploys nsgWeb first
          }
        }
      }
      {
        name: 'snet-app'
        properties: {
          addressPrefix: '10.20.2.0/24'
          defaultOutboundAccess: false
        }
      }
    ]
  }
}

// ---------- EXERCISE 3 - Log Analytics workspace -----------------------------

resource logs 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'log-nusa-${suffix}'
  location: location
  tags: allTags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// ---------- Outputs ----------------------------------------------------------

output storageAccountName string = storage.name
output storageBlobEndpoint string = storage.properties.primaryEndpoints.blob

// ---------- EXERCISE 4 - More outputs ----------------------------------------

output vnetId string = vnet.id
output webSubnetId string = vnet.properties.subnets[0].id
output logAnalyticsWorkspaceId string = logs.id
