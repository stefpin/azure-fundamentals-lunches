// =============================================================================
// Data: an Azure SQL logical server that accepts Microsoft Entra identities only,
// and one small serverless orders database (free offer by default).
// Pairs with Lunch 11 (Azure SQL) and Lunch 17 (automatic backups, point-in-time restore).
// =============================================================================

@description('Azure region.')
param location string

@description('Tags for every resource.')
param tags object

@description('Globally unique name of the logical server, for example sql-nusa-ab12c.')
param serverName string

@description('Name of the orders database.')
param databaseName string = 'sqldb-orders'

@description('Microsoft Entra user principal name of the server administrator.')
param adminLogin string

@description('Microsoft Entra object ID of the server administrator.')
param adminObjectId string

@description('true = free offer database that pauses when the monthly free allowance is used up. false = small paid serverless database.')
param useFreeOffer bool = true

// Settings shared by both database options. Bicep has no decimal literals, so json('0.5')
// expresses the 0.5 vCore minimum of a serverless database.
var commonDatabaseProperties = {
  autoPauseDelay: 60                        // minutes without connections before the database pauses
  minCapacity: json('0.5')
  maxSizeBytes: 34359738368                 // 32 GB, the free offer's data allowance
  requestedBackupStorageRedundancy: 'Local' // cheapest backup storage; production would choose deliberately (Lunch 17)
  zoneRedundant: false                      // production: true (see review-checklist.md)
}

var freeOfferProperties = {
  useFreeLimit: true
  freeLimitExhaustionBehavior: 'AutoPause' // never bills: pauses until next month instead
}

resource server 'Microsoft.Sql/servers@2023-08-01' = {
  name: serverName
  location: location
  tags: tags
  properties: {
    version: '12.0'
    minimalTlsVersion: '1.2'
    // The public endpoint exists but has no firewall rules, so no client can connect yet.
    // Private endpoints replace it in the deep-dive month (Lunch 28).
    publicNetworkAccess: 'Enabled'
    // Microsoft Entra-only authentication: no SQL logins, no passwords to leak.
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: 'User'
      login: adminLogin
      sid: adminObjectId
      tenantId: subscription().tenantId
      azureADOnlyAuthentication: true
    }
  }
}

resource database 'Microsoft.Sql/servers/databases@2023-08-01' = {
  parent: server
  name: databaseName
  location: location
  tags: tags
  sku: {
    name: 'GP_S_Gen5' // General Purpose, serverless, standard-series (Gen5) hardware
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: useFreeOffer ? 2 : 1 // maximum vCores while running
  }
  properties: useFreeOffer ? union(commonDatabaseProperties, freeOfferProperties) : commonDatabaseProperties
}

output serverName string = server.name
output serverFqdn string = server.properties.fullyQualifiedDomainName
output databaseName string = database.name
