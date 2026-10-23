// =============================================================================
// Lab 21 · Core capstone — Nusantara Retail's core platform in one deployment.
//
// Deploy it with ../deploy.sh: the script fills in who you are, runs what-if
// first and asks before it changes anything.
//
// Each module is small on purpose. Open one, read it, and match it to a lunch:
//   modules/network.bicep     Lunch 08  virtual network, private subnets, NSGs
//   modules/web.bicep         Lunches 03, 06, 09  zones, VMs, Standard load balancer
//   modules/sql.bicep         Lunches 11, 17  Azure SQL, Entra-only auth, backups
//   modules/keyvault.bicep    Lunch 15  Key Vault with Azure RBAC
//   modules/monitoring.bicep  Lunch 16  Log Analytics, action group, alerts
//   modules/policy.bicep      Lunch 18  Allowed locations policy
// =============================================================================
targetScope = 'resourceGroup'

@description('Azure region for every resource. The Allowed locations policy only allows this region.')
param location string = resourceGroup().location

@description('Short random suffix that keeps globally unique names unique (SUFFIX in labs/common/config.sh).')
@minLength(3)
@maxLength(8)
param suffix string

@description('Size of each web VM. Two VMs run at the same time (4 vCPUs in total). Only current sizes: new subscriptions cannot deploy B-series v1 such as Standard_B1s.')
@allowed([
  'Standard_B2ats_v2'
  'Standard_B2ts_v2'
  'Standard_B2als_v2'
  'Standard_B2s_v2'
])
param vmSize string = 'Standard_B2ats_v2'

@description('Admin user on the web VMs. Sign-in is by SSH key only; there is no password.')
param adminUsername string = 'azureuser'

@description('SSH public key for the admin user (deploy.sh reads ~/.ssh/id_rsa.pub).')
param sshPublicKey string

@description('Microsoft Entra user principal name of the Azure SQL administrator (you).')
param sqlAdminLogin string

@description('Microsoft Entra object ID of the Azure SQL administrator (you). The same person gets the Key Vault Secrets Officer role.')
param sqlAdminObjectId string

@description('E-mail address that receives alert notifications.')
param alertEmail string

@description('true = Azure SQL Database free offer (pauses when the monthly free allowance is used up). false = a small paid serverless database.')
param useFreeSqlOffer bool = true

@description('Tags added to every resource. Tags power cost reports (Lunch 19) and governance (Lunch 18).')
param tags object = {
  course: 'azure-fundamentals-lunches'
  lunch: '21'
  workload: 'storefront'
  environment: 'lab'
}

// The connection string holds no password: Azure SQL accepts only Microsoft Entra identities.
var sqlConnectionString = 'Server=tcp:${sql.outputs.serverFqdn},1433;Database=${sql.outputs.databaseName};Encrypt=True;Authentication=Active Directory Default;'

module network 'modules/network.bicep' = {
  name: 'network'
  params: {
    location: location
    tags: tags
  }
}

module web 'modules/web.bicep' = {
  name: 'web'
  params: {
    location: location
    tags: tags
    suffix: suffix
    subnetId: network.outputs.webSubnetId
    vmSize: vmSize
    adminUsername: adminUsername
    sshPublicKey: sshPublicKey
  }
}

module sql 'modules/sql.bicep' = {
  name: 'sql'
  params: {
    location: location
    tags: tags
    serverName: 'sql-nusa-${suffix}'
    adminLogin: sqlAdminLogin
    adminObjectId: sqlAdminObjectId
    useFreeOffer: useFreeSqlOffer
  }
}

module keyvault 'modules/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    location: location
    tags: tags
    vaultName: 'kv-nusa-${suffix}'
    secretsOfficerObjectId: sqlAdminObjectId
    sqlConnectionString: sqlConnectionString
  }
}

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    location: location
    tags: tags
    alertEmail: alertEmail
    webVmIds: web.outputs.vmIds
    loadBalancerId: web.outputs.loadBalancerId
    keyVaultName: keyvault.outputs.name
  }
}

module policy 'modules/policy.bicep' = {
  name: 'policy'
  params: {
    allowedLocations: [
      location
    ]
  }
}

output storefrontUrl string = 'http://${web.outputs.publicIpFqdn}/'
output publicIpAddress string = web.outputs.publicIpAddress
output sqlServerFqdn string = sql.outputs.serverFqdn
output sqlDatabaseName string = sql.outputs.databaseName
output keyVaultName string = keyvault.outputs.name
output workspaceName string = monitoring.outputs.workspaceName
