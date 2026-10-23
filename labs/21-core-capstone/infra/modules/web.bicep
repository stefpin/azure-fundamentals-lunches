// =============================================================================
// Web tier: a zone-redundant Standard public IP, a Standard load balancer and
// two Ubuntu web servers in availability zones 1 and 2 (no public IPs).
// Pairs with Lunch 03 (zones), Lunch 06 (VMs) and Lunch 09 (load balancing).
// =============================================================================

@description('Azure region (must have availability zones).')
param location string

@description('Tags for every resource.')
param tags object

@description('Short random suffix, used for the DNS name of the public IP.')
param suffix string

@description('Resource ID of the web subnet.')
param subnetId string

@description('Size of each web VM.')
param vmSize string

@description('Admin user on the VMs.')
param adminUsername string

@description('SSH public key for the admin user.')
param sshPublicKey string

@description('One web VM per zone in this list.')
param zones array = [
  '1'
  '2'
]

// The shared web server set-up lives in labs/common/cloud-init-web.yml.
// loadFileAsBase64() resolves paths relative to THIS file:
//   labs/21-core-capstone/infra/modules  ->  ../../../common  =  labs/common
var cloudInit = loadFileAsBase64('../../../common/cloud-init-web.yml')

var lbName = 'lb-nusa-shop'
var frontendName = 'fe-shop'
var backendPoolName = 'be-web'
var probeName = 'probe-health'

// Zone-redundant Standard public IP: listed in all three zones, so losing one zone
// does not take the storefront's address with it. Standard IPs are closed to inbound
// traffic until an NSG allows it (Basic SKU IPs were retired in September 2025).
resource pip 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'pip-nusa-shop'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: 'nusa-shop-${suffix}'
    }
  }
}

resource lb 'Microsoft.Network/loadBalancers@2024-05-01' = {
  name: lbName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: frontendName
        properties: {
          publicIPAddress: {
            id: pip.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: backendPoolName
      }
    ]
    probes: [
      {
        name: probeName
        properties: {
          protocol: 'Http'
          port: 80
          requestPath: '/health'
          intervalInSeconds: 5
          probeThreshold: 2
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'rule-http'
        properties: {
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName, frontendName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, backendPoolName)
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName, probeName)
          }
          loadDistribution: 'Default'
          idleTimeoutInMinutes: 4
          enableTcpReset: true
          // The outbound rule below handles outbound traffic, so this rule must not.
          disableOutboundSnat: true
        }
      }
    ]
    // Explicit outbound access for the private subnet: the VMs reach the internet
    // (for updates) through the load balancer's public IP.
    outboundRules: [
      {
        name: 'outbound-web'
        properties: {
          protocol: 'All'
          frontendIPConfigurations: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName, frontendName)
            }
          ]
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, backendPoolName)
          }
          allocatedOutboundPorts: 1024
          idleTimeoutInMinutes: 4
          enableTcpReset: true
        }
      }
    ]
  }
}

resource nics 'Microsoft.Network/networkInterfaces@2024-05-01' = [for i in range(0, length(zones)): {
  name: 'nic-vm-web-${i + 1}'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
          // No public IP here on purpose: the load balancer is the only way in.
          loadBalancerBackendAddressPools: [
            {
              id: lb.properties.backendAddressPools[0].id
            }
          ]
        }
      }
    ]
  }
}]

resource vms 'Microsoft.Compute/virtualMachines@2024-07-01' = [for (zone, i) in zones: {
  name: 'vm-web-${i + 1}'
  location: location
  tags: tags
  zones: [
    zone
  ]
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      // Ubuntu Server 24.04 LTS, Gen2 (the CLI alias Ubuntu2404).
      imageReference: {
        publisher: 'Canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
      osDisk: {
        name: 'osdisk-vm-web-${i + 1}'
        createOption: 'FromImage'
        deleteOption: 'Delete'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    osProfile: {
      computerName: 'vm-web-${i + 1}'
      adminUsername: adminUsername
      customData: cloudInit
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nics[i].id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}]

output vmIds array = [for i in range(0, length(zones)): vms[i].id]
output vmNames array = [for i in range(0, length(zones)): vms[i].name]
output loadBalancerId string = lb.id
output publicIpAddress string = pip.properties.ipAddress
output publicIpFqdn string = pip.properties.dnsSettings.fqdn
