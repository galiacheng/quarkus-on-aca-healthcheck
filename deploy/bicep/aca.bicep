// general Azure Container App settings
param location string
param name string
param containerAppEnvironmentId string

// Container Image ref
param containerImage string

// Networking
param useExternalIngress bool = false
param containerPort int
param containerRegistry string 

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
    name: name
    location: location
    properties: {
        managedEnvironmentId: containerAppEnvironmentId
        configuration: {
            ingress: {
                external: useExternalIngress
                targetPort: containerPort
            }
        }
        template: {
            containers: [
                {
                    image: containerImage
                    name: name
                    env: [
                        {
                            name: 'PORT'
                            value: '${containerPort}'
                        }
                    ]
                    probes: [
                        {
                            type: 'liveness'
                            initialDelaySeconds: 15
                            periodSeconds: 30
                            failureThreshold: 3
                            timeoutSeconds: 1
                            httpGet: {
                                port: containerPort
                                path: '/q/health/live'
                            }
                        }
                        {
                            type: 'startup'
                            timeoutSeconds: 2
                            httpGet: {
                                port: containerPort
                                path: '/q/health/started'
                            }
                        }
                        {
                            type: 'readiness'
                            timeoutSeconds: 3
                            failureThreshold: 3
                            httpGet: {
                                port: containerPort
                                path: '/q/health/ready'
                            }
                        }
                    ]
                }
            ]
            scale: {
                minReplicas: 12
            }
        }
    }
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01' existing = {
  name: containerRegistry
}

// Grant AcrPull role to the Container App's managed identity
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(containerApp.id, 'AcrPull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull role
    principalId: containerApp.identity.principalId
  }
}

output fqdn string = containerApp.properties.configuration.ingress.fqdn
