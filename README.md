### Main Steps: Customize Health Probe for Quarkus App on Azure Container Apps

#### 1. Set Environment Variables

```bash
export UNIQUE_VALUE=haiche1125
export RESOURCE_GROUP="${UNIQUE_VALUE}-aca-quarkus-rg"
export LOCATION="australiaeast"
export REGISTRY_NAME="${UNIQUE_VALUE}acrquarkusapp"
```

#### 2. Create Azure Container Registry (ACR)

1. **Create a Resource Group**  
   ```bash
   az group create --name ${RESOURCE_GROUP} --location ${LOCATION}
   ```

2. **Create the ACR**  
   ```bash
   az acr create --resource-group $RESOURCE_GROUP --location ${LOCATION} --name $REGISTRY_NAME --sku Basic
   ```

3. **Get ACR Login Server**  
   ```bash
   export LOGIN_SERVER=$(az acr show --name $REGISTRY_NAME --query 'loginServer' --output tsv)
   echo $LOGIN_SERVER
   ```

#### 3. Build the Container Image

- **Build Traditional Image**  
   ```bash
   export QUARKUS_IMAGE_TAG=${LOGIN_SERVER}/quarkus-aca:1.0
   quarkus build -Dquarkus.container-image.build=true -Dquarkus.container-image.image=${QUARKUS_IMAGE_TAG}
   ```

- **Build Native Image**  
   ```bash
   export QUARKUS_IMAGE_TAG=${LOGIN_SERVER}/quarkus-aca-native:1.0
   ./mvnw package -Dnative -Dquarkus.native.container-build=true -Dquarkus.container-image.build=true -Dquarkus.container-image.image=${QUARKUS_IMAGE_TAG}
   ```

#### 4. Push Image to ACR

1. **Log in to ACR**  
   ```bash
   az acr login --name $REGISTRY_NAME
   ```

2. **Push the Image**  
   ```bash
   docker push ${QUARKUS_IMAGE_TAG}
   ```

#### 5. Deploy the Quarkus App

##### **Using Azure CLI**

1. **Create a Container Environment**  
   ```bash
   export ENVIRONMENT="${UNIQUE_VALUE}-env-dev-test-quarkus-health"
   az containerapp env create --name $ENVIRONMENT --resource-group $RESOURCE_GROUP --location $LOCATION
   ```

2. **Create a User-Assigned Managed Identity**  
   ```bash
   export UAMI_NAME="${UNIQUE_VALUE}-uami-with-acr-pull"
   az identity create --name ${UAMI_NAME} --resource-group ${RESOURCE_GROUP}
   ```

   Retrieve the Managed Identity IDs:  
   ```bash
   export UAMI_CLIENT_ID=$(az identity show --name ${UAMI_NAME} --resource-group ${RESOURCE_GROUP} --query "clientId" --output tsv)
   export UAMI_ID=$(az identity show --name ${UAMI_NAME} --resource-group ${RESOURCE_GROUP} --query "id" --output tsv)
   ```

3. **Grant `AcrPull` Permission**  
   ```bash
   export CONTAINER_APP_NAME="${UNIQUE_VALUE}-quarkus-health"
   az role assignment create \
     --assignee ${UAMI_CLIENT_ID} \
     --role "AcrPull" \
     --scope $(az acr show --name ${REGISTRY_NAME} --query id --output tsv)
   ```

4. **Generate YAML Configuration**  
   ```bash
   cd deploy/yaml
   bash gen-yaml-configuration.sh
   ```

5. **Create the Container App**  
   ```bash
   az containerapp create \
     --name ${CONTAINER_APP_NAME} \
     --environment $ENVIRONMENT \
     --resource-group $RESOURCE_GROUP \
     --yaml quarkus.yaml
   ```

##### **Using Bicep**

1. Navigate to the Bicep Directory:  
   ```bash
   cd deploy/bicep
   ```

2. Deploy Using Bicep:  
   ```bash
   az deployment group create --resource-group ${RESOURCE_GROUP} --template-file main.bicep \
     --parameters acrImage=${QUARKUS_IMAGE_TAG} containerRegistry=${REGISTRY_NAME}
   ```

#### 6. Verify Deployment

1. **Check Health Probes**  
   Open the Azure portal, navigate to the container app you created, and go to **Containers** -> **Health Probes** to view the custom probe configuration.
   
   To test a negative case, set `database.up=false` in `resources/application.properties`, rebuild the app, and deploy it again. You will notice that the deployment fails as expected.

   Command to update the image:

   ```bash
   az containerapp update \
     --name <container app name> \
     --resource-group $RESOURCE_GROUP \
     --image <new image>
   ```

2. **Check App Logs**  
   ```bash
   az containerapp logs show --name ${CONTAINER_APP_NAME} --resource-group ${RESOURCE_GROUP}
   ```