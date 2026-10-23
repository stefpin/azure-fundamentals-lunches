// =============================================================================
// Secrets: a Key Vault that uses the Azure RBAC permission model, one example
// secret, and a data-plane role for the person running the deployment.
// Pairs with Lunch 15 (Key Vault, RBAC, soft delete, managed identities).
// =============================================================================

@description('Azure region.')
param location string

@description('Tags for every resource.')
param tags object

@description('Globally unique vault name (3-24 characters), for example kv-nusa-ab12c.')
@minLength(3)
@maxLength(24)
param vaultName string

@description('Object ID of the person who manages secrets (you). Gets Key Vault Secrets Officer on this vault only.')
param secretsOfficerObjectId string

@description('Connection string for the orders database. It holds no password (Entra authentication), but we still treat it as a secret out of habit.')
@secure()
param sqlConnectionString string

// Bicep cannot look up a built-in role by its name, so it needs the role definition ID.
// "Key Vault Secrets Officer" has the same ID in every tenant. Check it yourself:
//   az role definition list --name "Key Vault Secrets Officer" --query "[0].name" --output tsv
var keyVaultSecretsOfficerRoleId = 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'

resource vault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: vaultName
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    // Azure RBAC decides who may read or change secrets (no access policies).
    enableRbacAuthorization: true
    // Deleted vaults and secrets stay recoverable for 7 days (the minimum).
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    // Purge protection stays off so cleanup.sh can remove the lab completely.
    // Turn it on in production (see review-checklist.md).
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource connectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vault
  name: 'sql-connection-string'
  properties: {
    value: sqlConnectionString
    contentType: 'text/plain'
  }
}

// Least privilege: the role is assigned on this vault only, not on the resource group.
resource secretsOfficer 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(vault.id, secretsOfficerObjectId, keyVaultSecretsOfficerRoleId)
  scope: vault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsOfficerRoleId)
    principalId: secretsOfficerObjectId
    principalType: 'User'
  }
}

output name string = vault.name
output id string = vault.id
output uri string = vault.properties.vaultUri
