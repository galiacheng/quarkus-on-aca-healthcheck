param location string = resourceGroup().location
param name string = 'quarkus-healthcheck'

param containerImage string
param containerPort int = 8080
param containerRegistry string

module law 'log-analytics.bicep' = {
	name: 'log-analytics-workspace'
	params: {
      location: location
      name: 'law-${name}'
	}
}

module containerAppEnvironment 'aca-environment.bicep' = {
  name: 'aca-env-${name}'
  params: {
    name: 'env-${name}'
    location: location
    lawClientId:law.outputs.clientId
    lawClientSecret: law.outputs.clientSecret
  }
}

module containerApp 'aca.bicep' = {
  name: 'api'
  params: {
    name: 'api'
    location: location
    containerAppEnvironmentId: containerAppEnvironment.outputs.id
    containerImage: containerImage
    containerPort: containerPort
    containerRegistry: containerRegistry
    useExternalIngress: true
  }
}

output fqdn string = containerApp.outputs.fqdn
