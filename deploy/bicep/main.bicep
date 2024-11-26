param location string = resourceGroup().location
param name string = 'quarkus-healthcheck'

param acrImage string
param containerPort int = 8080
param containerRegistry string

module law 'log-analytics.bicep' = {
  name: 'log-analytics-workspace'
  params: {
    location: location
    name: 'law-${name}'
  }
}

module containerAppEnvironment 'aca-env.bicep' = {
  name: 'aca-env-${name}'
  params: {
    name: 'env-${name}'
    location: location
    lawClientId: law.outputs.clientId
    lawClientSecret: law.outputs.clientSecret
  }
}

module uami 'uami.bicep' = {
  name: 'uami'
  params: {
    location: location
    name: 'uami-${name}'
    acrName: containerRegistry
  }
}

module containerApp 'aca.bicep' = {
  name: 'aca-${name}'
  params: {
    name: 'aca-${name}'
    location: location
    containerAppEnvironmentId: containerAppEnvironment.outputs.id
    acrLoginServer: uami.outputs.acrLoginServer
    acrImage: acrImage
    containerPort: containerPort
    useExternalIngress: true
    uamiId: uami.outputs.uamiId
  }
}

output fqdn string = containerApp.outputs.fqdn
