Main steps:

Env variables:

```bash
export UNIQUE_VALUE=haiche1125
export RESOURCE_GROUP="${UNIQUE_VALUE}-aca-quarkus-rg"
export LOCATION="australiaeast"
export REGISTRY_NAME="${UNIQUE_VALUE}acrquarkusapp"
```

1. Create ACR

   ```bash
   az group create --name ${RESOURCE_GROUP} --location ${LOCATION}
   ```


   ```bash
   az acr create --resource-group $RESOURCE_GROUP --location ${LOCATION} --name $REGISTRY_NAME --sku Basic
   ```

   ```bash
   export LOGIN_SERVER=$(az acr show --name $REGISTRY_NAME --query 'loginServer' --output tsv)
   echo $LOGIN_SERVER
   ```

1. Build image

   Build traditional image:

   ```bash
   export QUARKUS_IMAGE_TAG=${LOGIN_SERVER}/quarkus-aca:1.0
   quarkus build -Dquarkus.container-image.build=true -Dquarkus.container-image.image=${QUARKUS_IMAGE_TAG} --no-tests
   ```

   Build native image:

   ```bash
   export QUARKUS_IMAGE_TAG=${LOGIN_SERVER}/quarkus-aca-native:1.0
   ./mvnw package -Dnative -Dquarkus.native.container-build=true -Dquarkus.container-image.build=true
   ```

1. Push image to ACR

   ```bash
   az acr login --name $REGISTRY_NAME
   ```

   ```bash
   docker push ${QUARKUS_IMAGE_TAG}
   ```

1. Deploy Quarkus app to ACR

   ## AZ CLI

   Create container environment

   ```bash
   export ENVIRONMENT="${UNIQUE_VALUE}-env-dev-test-quarkus-health"   

   az containerapp env create --name $ENVIRONMENT --resource-group $RESOURCE_GROUP --location $LOCATION
   ```

   Create a user assigned managed identity and grant AcrPull permission to the identity.

   ```bash
   export UAMI_NAME="${UNIQUE_VALUE}-uami-with-acr-pull"
   az identity create --name ${UAMI_NAME} --resource-group ${RESOURCE_GROUP}
   ```

   ```bash
   export UAMI_CLIENT_ID=$(az identity show --name ${UAMI_NAME} --resource-group ${RESOURCE_GROUP} --query "clientId" --output tsv)
   export UAMI_ID=$(az identity show --name ${UAMI_NAME} --resource-group ${RESOURCE_GROUP} --query "id" --output tsv)
   ```

   Assign the `AcrPull` Role.

   ```bash
   export CONTAINER_APP_NAME="${UNIQUE_VALUE}-quarkus-health"
   
   az role assignment create \
    --assignee ${UAMI_CLIENT_ID} \
    --role "AcrPull" \
    --scope $(az acr show --name ${REGISTRY_NAME} --query id --output tsv)
   ```

   Generate Yaml configurtion.

   ```bash
   cd deploy/yaml
   bash gen-yaml-configuration.sh
   ```
   Create container app.

   ```bash
   az containerapp create \
     --name ${CONTAINER_APP_NAME} \
     --environment $ENVIRONMENT \
     --resource-group $RESOURCE_GROUP \
     --yaml quarkus.yaml
   ```
   
   ## Bicep

   ```bash
   cd deploy/bicep
   ```

   ```bash
   az deployment group create -g ${RESOURCE_GROUP} -f main.bicep -p acrImage=${QUARKUS_IMAGE_TAG} containerRegistry=${REGISTRY_NAME}
   ```

1. Check health probe

1. Check App health