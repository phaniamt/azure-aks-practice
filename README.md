## Azure aks cluster create and manage using azure cli

### Install azure cli 
```
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

- **Reference Documentation Links**
- https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

***

### Login to azure account via cli
```
# Login using username and password
az login -u <username> -p <password>

# Login using service-principal
az login --service-principal -u <app-url> -p <password-or-cert> --tenant <tenant>

```
- **Reference Documentation Links**
- https://docs.microsoft.com/en-us/cli/azure/reference-index?view=azure-cli-latest#az_login
  
### Before Create the aks cluster export the values as envs for reuse

```
# Edit export statements to make any changes required as per your environment
# Execute below export statements
AKS_RESOURCE_GROUP=aks-rg
AKS_REGION=centralus
echo $AKS_RESOURCE_GROUP, $AKS_REGION
```

### Create the resoure group for aks 

```
az group create --location ${AKS_REGION} \
                --name ${AKS_RESOURCE_GROUP}
```

### Export envs for VNET and Subnet

```
AKS_VNET=aks-vnet
AKS_VNET_ADDRESS_PREFIX=10.0.0.0/8
AKS_VNET_SUBNET_DEFAULT=aks-subnet-default
AKS_VNET_SUBNET_DEFAULT_PREFIX=10.240.0.0/16
AKS_VNET_SUBNET_APPGW=aks-subnet-appgw
AKS_VNET_SUBNET_APPGW_PREFIX=10.241.0.0/16
```

### Create Virtual Network & default Subnet

```
az network vnet create -g ${AKS_RESOURCE_GROUP} \
                       -n ${AKS_VNET} \
                       --address-prefix ${AKS_VNET_ADDRESS_PREFIX} \
                       --subnet-name ${AKS_VNET_SUBNET_DEFAULT} \
                       --subnet-prefix ${AKS_VNET_SUBNET_DEFAULT_PREFIX} \
                       --location ${AKS_REGION}
```

### Create additional subnet for application gateway (L7 Loadbalancer in azure)

```
az network vnet subnet create \
    --resource-group ${AKS_RESOURCE_GROUP} \
    --vnet-name ${AKS_VNET} \
    --name ${AKS_VNET_SUBNET_APPGW} \
    --address-prefixes ${AKS_VNET_SUBNET_APPGW_PREFIX}
```

- **Reference Documentation Links**
- https://docs.microsoft.com/en-us/cli/azure/network/vnet?view=azure-cli-latest#az_network_vnet_create
- https://docs.microsoft.com/en-us/cli/azure/network/vnet/subnet?view=azure-cli-latest#az_network_vnet_subnet_create

### Get Virtual Network default subnet id

```
AKS_VNET_SUBNET_DEFAULT_ID=$(az network vnet subnet show \
                           --resource-group ${AKS_RESOURCE_GROUP} \
                           --vnet-name ${AKS_VNET} \
                           --name ${AKS_VNET_SUBNET_DEFAULT} \
                           --query id \
                           -o tsv)
echo ${AKS_VNET_SUBNET_DEFAULT_ID}
```

***

### Generate ssh key for connect the aks nodes via ssh 

```
# Create Folder
mkdir $HOME/.ssh/aks-sshkeys

# Create SSH Key . if exist overwrite
ssh-keygen -f ~/.ssh/aks-sshkeys/sshkey -q -N "" <<<y 2>&1 >/dev/null
# List Files
ls -lrt $HOME/.ssh/aks-sshkeys

# Set SSH KEY Path
AKS_SSH_KEY_LOCATION=$HOME/.ssh/aks-sshkeys/sshkey.pub
echo $AKS_SSH_KEY_LOCATION
```

### Create Log Analytics Workspace

```
WORKSPACE_NAME=my-aks-workspace

AKS_MONITORING_LOG_ANALYTICS_WORKSPACE_ID=$(az monitor log-analytics workspace create   --resource-group ${AKS_RESOURCE_GROUP} \
                                           --workspace-name ${WORKSPACE_NAME} --location ${AKS_REGION} \
                                           --query id \
                                           -o tsv)

echo $AKS_MONITORING_LOG_ANALYTICS_WORKSPACE_ID
```

***

### Create ACR repo for store the docker images and deploy it in aks 

```
ACR_NAME=myacr

az acr create --name $ACR_NAME --resource-group ${AKS_RESOURCE_GROUP} --sku Standard --location ${AKS_REGION}

# Import a docker image from public docker hub to acr
az acr import  -n $ACR_NAME --source docker.io/library/nginx:1.19.0 --image nginx:1.19.0
```
- **Note: This is used in CI/CD tool only . Not required for aks**
### Create a service principal for push and pull the images from acr 

```
SERVICE_PRINCIPAL_NAME=acr-service-principal
```

- **Obtain the full registry ID for subsequent command args**

```
ACR_REGISTRY_ID=$(az acr show --name $ACR_NAME --query id --output tsv)
```


- **Create the service principal with rights scoped to the registry.**
- **Default permissions are for docker pull access. Modify the '--role'**
- **argument value as desired:**
- **acrpull:     pull only**
- **acrpush:     push and pull**
- **owner:       push, pull, and assign roles**


```
SP_PASSWD=$(az ad sp create-for-rbac --name http://$SERVICE_PRINCIPAL_NAME --scopes $ACR_REGISTRY_ID --role acrpush --query password --output tsv)
SP_APP_ID=$(az ad sp show --id http://$SERVICE_PRINCIPAL_NAME --query appId --output tsv)
```

- **Output the service principal's credentials; use these in your services and**
- **applications to authenticate to the container registry.**
***

```
echo "Service principal ID: $SP_APP_ID"
echo "Service principal password: $SP_PASSWD"
```
- **Log in to Docker with service principal credentials**

```
docker login phaniacr.azurecr.io --username $SP_APP_ID --password $SP_PASSWD
```

