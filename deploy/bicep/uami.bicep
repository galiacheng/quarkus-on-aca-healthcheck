// general uami and grant access to pull image
param location string
param name string
param acrName string
// Resources
// Reference the existing ACR
resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = {
  name: acrName
}

// User-assigned managed identity resource
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
}

// Assign the AcrPull role to the user-assigned managed identity
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, userAssignedIdentity.id, 'AcrPull')
  scope: acr
  properties: {
    description: 'Assign the AcrPull role'
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    ) // AcrPull role
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output uamiId string = userAssignedIdentity.id
output acrLoginServer string = acr.properties.loginServer
