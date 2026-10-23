// =============================================================================
// Governance: assign the built-in "Allowed locations" policy to this resource group,
// so nobody can create resources outside the approved region(s).
// Pairs with Lunch 18 (Azure Policy) and Lunch 31 (governance at scale).
// =============================================================================
targetScope = 'resourceGroup'

@description('Regions where new resources in this resource group may be created.')
param allowedLocations array

// Bicep cannot look up a built-in policy by its display name, so it needs the definition ID.
// The built-in "Allowed locations" policy (category General, effect Deny by default) has the
// same ID in every tenant:
//   /providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c
// It excludes resource groups and resources whose location is 'global' (action groups, alert rules).
// Check it yourself:
//   az policy definition list --query "[?displayName=='Allowed locations'].name" --output tsv
var allowedLocationsDefinitionId = 'e56962a6-4747-49cd-b67b-bf8b01975c4c'

resource allowedLocations 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'allowed-locations'
  properties: {
    displayName: 'Nusantara Retail: allowed locations (capstone)'
    description: 'Deny new resources outside the approved region(s). Customer data stays where the business decided.'
    policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', allowedLocationsDefinitionId)
    enforcementMode: 'Default'
    parameters: {
      listOfAllowedLocations: {
        value: allowedLocations
      }
    }
    nonComplianceMessages: [
      {
        message: 'Nusantara Retail keeps this workload in its approved region. Choose an allowed location.'
      }
    ]
  }
}

output assignmentName string = allowedLocations.name
output assignmentId string = allowedLocations.id
