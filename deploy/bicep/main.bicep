param location string = resourceGroup().location
param name string = newGuid()

param acrImage string
param containerPort int = 8080
param containerRegistry string

var acaName='${name}-aca-quarkus-health'

module law 'log-analytics.bicep' = {
  name: 'log-analytics-workspace'
  params: {
    location: location
    name: '${name}-law-quarkus-health'
  }
}

module containerAppEnvironment 'aca-env.bicep' = {
  name: 'aca-env-${name}'
  params: {
    name: '${name}-aca-env-quarkus-health'
    location: location
    lawClientId: law.outputs.clientId
    lawClientSecret: law.outputs.clientSecret
  }
}

module uami 'uami.bicep' = {
  name: 'uami'
  params: {
    location: location
    name: '${name}-uami-quarkus-health'
    acrName: containerRegistry
  }
}

module containerApp 'aca.bicep' = {
  name: 'aca'
  params: {
    name: acaName
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
