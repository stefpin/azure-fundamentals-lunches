// =============================================================================
// Operations: a Log Analytics workspace, an action group that e-mails the
// on-call engineer, three alert rules, and Key Vault audit logs.
// Pairs with Lunch 16 (Azure Monitor, alerts, action groups) and Lunch 30 (Log Analytics).
// =============================================================================

@description('Azure region.')
param location string

@description('Tags for every resource.')
param tags object

@description('E-mail address of the on-call engineer.')
param alertEmail string

@description('Resource IDs of the web VMs to watch.')
param webVmIds array

@description('Resource ID of the load balancer to watch.')
param loadBalancerId string

@description('Name of the Key Vault whose audit logs go to the workspace.')
param keyVaultName string

@description('Name of the Log Analytics workspace.')
param workspaceName string = 'log-nusa'

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    workspaceCapping: {
      dailyQuotaGb: 1 // lab-sized safety cap on ingestion cost
    }
  }
}

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-nusa-oncall'
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'nusaoncall' // at most 12 characters; shown in SMS and e-mail subjects
    enabled: true
    emailReceivers: [
      {
        name: 'oncall-email'
        emailAddress: alertEmail
        useCommonAlertSchema: true
      }
    ]
  }
}

// 1) Capacity: average CPU on any web VM above 80% for five minutes.
//    One rule watches both VMs (a multi-resource metric alert).
resource cpuAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-web-cpu-high'
  location: 'global'
  tags: tags
  properties: {
    description: 'Average CPU on a web VM stayed above 80 percent for 5 minutes. Consider scaling out (Lunch 23).'
    severity: 2
    enabled: true
    scopes: webVmIds
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    targetResourceType: 'Microsoft.Compute/virtualMachines'
    targetResourceRegion: location
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          name: 'HighCpu'
          metricNamespace: 'Microsoft.Compute/virtualMachines'
          metricName: 'Percentage CPU'
          operator: 'GreaterThan'
          threshold: 80
          timeAggregation: 'Average'
        }
      ]
    }
    autoMitigate: true
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// 2) Application health: a RUNNING web server stops answering the health probe
//    (for example, the web service crashed). Health Probe Status = metric DipAvailability.
//    Note: the load balancer does not probe deallocated VMs, so a stopped VM does not
//    lower this metric; alert 3 covers that case.
resource backendHealthAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-lb-backend-health'
  location: 'global'
  tags: tags
  properties: {
    description: 'Not every running web server answered the load balancer health probe on /health.'
    severity: 1
    enabled: true
    scopes: [
      loadBalancerId
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          name: 'ProbeHealth'
          metricNamespace: 'Microsoft.Network/loadBalancers'
          metricName: 'DipAvailability'
          operator: 'LessThan'
          threshold: 95
          timeAggregation: 'Average'
        }
      ]
    }
    autoMitigate: true
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// 3) Change tracking: someone stopped or deallocated a VM in this resource group.
//    Activity log alerts are free and fire on control-plane operations.
resource vmStoppedAlert 'Microsoft.Insights/activityLogAlerts@2020-10-01' = {
  name: 'alert-web-vm-stopped'
  location: 'global'
  tags: tags
  properties: {
    description: 'A VM in the storefront resource group was stopped or deallocated.'
    enabled: true
    scopes: [
      resourceGroup().id
    ]
    condition: {
      allOf: [
        {
          field: 'category'
          equals: 'Administrative'
        }
        {
          field: 'resourceType'
          equals: 'Microsoft.Compute/virtualMachines'
        }
        {
          anyOf: [
            {
              field: 'operationName'
              equals: 'Microsoft.Compute/virtualMachines/deallocate/action'
            }
            {
              field: 'operationName'
              equals: 'Microsoft.Compute/virtualMachines/powerOff/action'
            }
          ]
        }
        {
          field: 'status'
          equals: 'Succeeded'
        }
      ]
    }
    actions: {
      actionGroups: [
        {
          actionGroupId: actionGroup.id
        }
      ]
    }
  }
}

// Key Vault audit logs (who read which secret, and when) go to the workspace.
resource vault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource vaultDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${workspaceName}'
  scope: vault
  properties: {
    workspaceId: workspace.id
    logs: [
      {
        categoryGroup: 'audit'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output workspaceName string = workspace.name
output workspaceId string = workspace.id
output actionGroupId string = actionGroup.id
