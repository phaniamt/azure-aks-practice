# Create a storage-account and give access via service principle


### Export required envs
```
SA_RG=sa-practice
SA_REGION=centralus
SA_NAME=mytestsa
SERVICE_PRINCIPAL_NAME=my-sa-service-principal
SUB_ID=$(az account show --query id  --output tsv)
TN_ID=$(az account show --query tenantId  --output tsv)
CONTAINER=testing
```

### Create the resource-group

```
az group create \
    --name $SA_RG \
    --location $SA_REGION
```

### Create the storage-account

```
az storage account create \
    --name $SA_NAME \
    --resource-group $SA_RG \
    --location $SA_REGION \
    --sku Standard_ZRS \
    --encryption-services blob
```

### Create the service-principal

```
SP_PASSWD=$(az ad sp create-for-rbac --skip-assignment --name http://$SERVICE_PRINCIPAL_NAME --years 100 --query password --output tsv)
SP_APP_ID=$(az ad sp show --id http://$SERVICE_PRINCIPAL_NAME --query appId --output tsv)

# Get the service principal's credentials
echo "Service principal ID: $SP_APP_ID"
echo "Service principal password: $SP_PASSWD"
```

### Assign the permissions to service-principal
```
SA_ID=$(az storage account show -n $SA_NAME --query id -o tsv)

az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee $SP_APP_ID \
  --scope $SA_ID
```



### Login via azure cli using service-principal credentials

```
SP_APP_ID=3fcc1d4a-98e3-4b27-a0cc-707d8727a45f
SP_PASSWD=zqqoT5djR-Ev7xh3H_eMe9-ULb5BS.DeJv
TN_ID=014b7515-57a1-4bf1-9ef6-87f5ec672f74
CONTAINER=testing
  
az login --service-principal --username $SP_APP_ID --password $SP_PASSWD --tenant $TN_ID
```

### Export required envs

```
SA_NAME=mytestsa
CONTAINER=testing
```

### Create the container inside storage account

```
az storage container create \
    --account-name $SA_NAME \
    --name $CONTAINER \
    --auth-mode login
```

### Upload a file to container

```
az storage blob upload \
    --account-name $SA_NAME \
    --container-name $CONTAINER \
    --name helloworld \
    --file abcd.txt \
    --auth-mode login
```

### List the blobs inside the container

```
az storage blob list \
    --account-name $SA_NAME \
    --container-name $CONTAINER \
    --output table \
    --auth-mode login
```

### Download the blob from container

```
az storage blob download \
    --account-name $SA_NAME \
    --container-name $CONTAINER \
    --name helloworld \
    --file ./helloworld \
    --auth-mode login
```

### Delete the resource-group. it will delete all the resources inside that resource-group

```
az group delete \
    --name $SA_RG \
    --location $SA_REGION
```


### Set the auth-mode in env

```
AZURE_STORAGE_AUTH_MODE=login
```

- **Reference Documentation Links**

- https://docs.microsoft.com/en-us/azure/storage/blobs/authorize-data-operations-cli?toc=/azure/storage/blobs/toc.json

- https://docs.microsoft.com/en-us/azure/storage/blobs/storage-quickstart-blobs-cli

- https://docs.microsoft.com/en-us/azure/container-registry/container-registry-auth-service-principal

- https://docs.microsoft.com/en-us/cli/azure/storage/container?view=azure-cli-latest

