Main steps:

Env variables:

```bash
export RESOURCE_GROUP="aca-quarkus-rg"
export LOCATION="australiaeast"
export ENVIRONMENT="env-dev-test-quarkus-health"
export CONTAINER_APP_NAME="quarkus-health-1125"
export REGISTRY_NAME="acrquarkusapp1125"
export UAMI_NAME="uami-with-acr-pull"
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

1. Create container environment

   ```bash
   az containerapp env create --name $ENVIRONMENT --resource-group $RESOURCE_GROUP --location $LOCATION
   ```

1. Build image

   ```bash
   export QUARKUS_IMAGE_TAG=${LOGIN_SERVER}/quarkus-aca:1.0
   quarkus build -Dquarkus.container-image.build=true -Dquarkus.container-image.image=${QUARKUS_IMAGE_TAG} --no-tests
   ```

1. Push image to ACR

   ```bash
   az acr login --name $REGISTRY_NAME
   ```

   ```bash
   docker push ${QUARKUS_IMAGE_TAG}
   ```

1. Create a user assigned managed identity and grant AcrPull permission to the identity.

   ```bash
   az identity create --name ${UAMI_NAME} --resource-group ${RESOURCE_GROUP}
   ```

   ```bash
   export UAMI_CLIENT_ID=$(az identity show --name ${UAMI_NAME} --resource-group ${RESOURCE_GROUP} --query "clientId" --output tsv)
   ```

   Assign the `AcrPull` Role.

   ```bash
   az role assignment create \
    --assignee ${UAMI_CLIENT_ID} \
    --role "AcrPull" \
    --scope $(az acr show --name ${REGISTRY_NAME} --query id --output tsv)
   ```

1. Deploy Quarkus app to ACR

   ## AZ CLI

   ```bash
   az containerapp create \
    --name ${CONTAINER_APP_NAME} \
    --environment $ENVIRONMENT \
    --resource-group $RESOURCE_GROUP \
    --yaml quarkus.yaml
   ```
   
   ## Bicep

   ```bash
   ```

1. Check health probe

1. Check App health