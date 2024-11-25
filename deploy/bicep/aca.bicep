// general Azure Container App settings
param location string
param name string
param containerAppEnvironmentId string

// Container Image ref
param acrLoginServer string
param acrImage string

// Networking
param useExternalIngress bool = false
param containerPort int

// identity
param uamiId string

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: name
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uamiId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnvironmentId
    configuration: {
      registries: [
        {
          identity: '${uamiId}'
          server: acrLoginServer

        }
      ]
      ingress: {
        external: useExternalIngress
        targetPort: containerPort
      }
    }
    template: {
      containers: [
        {
          image: acrImage
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
        minReplicas: 1
      }
    }
  }
}

output fqdn string = containerApp.properties.configuration.ingress.fqdn
