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
- **Note: The below step required for  CI/CD tool only . Not required for aks**
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
docker login myacr.azurecr.io --username $SP_APP_ID --password $SP_PASSWD
```

### List Kubernetes Versions available as on today

```
az aks get-versions --location ${AKS_REGION} -o table
```

- **Set Cluster Name**

```
AKS_CLUSTER=akscluster
echo $AKS_CLUSTER
```

### Upgrade az CLI  (To latest version)
```
az --version
az upgrade
```

### Create AKS cluster

```
az aks create --resource-group ${AKS_RESOURCE_GROUP} \
              --location ${AKS_REGION} \
              --name ${AKS_CLUSTER} \
              --kubernetes-version 1.18.10 \
              --enable-managed-identity \
              --ssh-key-value  ${AKS_SSH_KEY_LOCATION} \
              --admin-username aksnodeadmin \
              --node-count 1 \
              --enable-cluster-autoscaler \
              --min-count 1 \
              --max-count 2 \
              --network-plugin azure \
              --service-cidr 10.0.0.0/16 \
              --dns-service-ip 10.0.0.10 \
              --docker-bridge-address 172.17.0.1/16 \
              --vnet-subnet-id ${AKS_VNET_SUBNET_DEFAULT_ID} \
              --node-osdisk-size 30 \
              --node-vm-size Standard_DS2_v2 \
              --nodepool-labels nodepool-type=system nodepoolos=linux app=system-apps \
              --nodepool-name systempool \
              --nodepool-tags nodepool-type=system nodepoolos=linux app=system-apps \
              --enable-addons monitoring \
              --workspace-resource-id ${AKS_MONITORING_LOG_ANALYTICS_WORKSPACE_ID} \
              --load-balancer-sku standard \
              --outbound-type loadBalancer \
              --attach-acr $ACR_NAME \
              --zones {1,2,3} --yes
```

### Configure Credentials

```
az aks get-credentials --name ${AKS_CLUSTER}  --resource-group ${AKS_RESOURCE_GROUP} --overwrite-existing
```

### Cluster Info

```
kubectl cluster-info
```


### List Node Pools

```
az aks nodepool list --cluster-name ${AKS_CLUSTER} --resource-group ${AKS_RESOURCE_GROUP} -o table
```

### Check the current aks cluster kubernetes-version

```
az aks show --resource-group ${AKS_RESOURCE_GROUP} --name ${AKS_CLUSTER} --query kubernetesVersion --output table
```

### List which pods are running in system nodepool from kube-system namespace

```
kubectl get pod -o=custom-columns=NODE-NAME:.spec.nodeName,POD-NAME:.metadata.name -n kube-system
```

### Get the MSI of our AKS cluster

```
az aks show -g ${AKS_RESOURCE_GROUP} -n ${AKS_CLUSTER} --query "identity"
```

- **Reference Documentation Links**
- https://docs.microsoft.com/en-us/azure/aks/cluster-autoscaler
- https://docs.microsoft.com/en-us/cli/azure/aks?view=azure-cli-latest#az_aks_create
- https://docs.microsoft.com/en-us/cli/azure/aks?view=azure-cli-latest

***

### Enable the application gateway addon feature in azure account

- **Reference Documentation Links**
- https://docs.microsoft.com/en-us/azure/application-gateway/tutorial-ingress-controller-add-on-new

```
az extension add --name aks-preview

# Enable application gateway addon 
az feature register --name AKS-IngressApplicationGatewayAddon --namespace Microsoft.ContainerService

# Check the Register status. it may take few minutes
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AKS-IngressApplicationGatewayAddon')].{Name:name,State:properties.state}"

# Refresh the registration of the Microsoft.ContainerService resource provider
az provider register --namespace Microsoft.ContainerService
```

### Create the new namespace

```
kubectl create ns web-server
```

### Enable addon for aks cluster

```
az aks enable-addons --name ${AKS_CLUSTER} --resource-group ${AKS_RESOURCE_GROUP} --addons ingress-appgw --appgw-subnet-id $APPGW_SUBNET_ID --appgw-name $APPGW_NAME --appgw-watch-namespace web-server,default
```

### Check the ssl certificate list in application gateway

```
az network application-gateway ssl-cert list -g MC_${AKS_RESOURCE_GROUP}_${AKS_CLUSTER}_${AKS_REGION} --gateway-name ${APPGW_NAME}
```

### Configure the ssl in application gateway

- **Fist generate the letsencrypt ssl using certbot or purchase the ssl

### Convert pem to pfx

```
CERT_PASSWD=1234
openssl pkcs12 -export -out certificate.pfx -inkey privkey1.pem -in fullchain1.pem -password pass:$CERT_PASSWD
```

### Convert pem to cer

```
openssl x509 -inform PEM -in fullchain1.pem -outform DER -out certificate.cer
```

### Add ssl to application gateway

```
CERT_NAME=myssl

az network application-gateway ssl-cert create -g MC_${AKS_RESOURCE_GROUP}_${AKS_CLUSTER}_${AKS_REGION} --gateway-name $APPGW_NAME \
    -n $CERT_NAME --cert-file certificate.pfx --cert-password $CERT_PASSWD

az network application-gateway ssl-cert list -g MC_${AKS_RESOURCE_GROUP}_${AKS_CLUSTER}_${AKS_REGION} --gateway-name ${APPGW_NAME}

az network application-gateway ssl-cert show  -g MC_${AKS_RESOURCE_GROUP}_${AKS_CLUSTER}_${AKS_REGION} --gateway-name ${APPGW_NAME} -n $CERT_NAME
```

- **Reference Documentation Links**

- https://github.com/Azure/application-gateway-kubernetes-ingress/tree/master/docs/examples/sample-app

- https://azure.github.io/application-gateway-kubernetes-ingress/annotations/#ssl-redirect

- https://azure.github.io/application-gateway-kubernetes-ingress/features/appgw-ssl-certificate/

- https://docs.microsoft.com/en-us/cli/azure/network/application-gateway/ssl-cert?view=azure-cli-latest

### Another method for add the ssl

```
kubectl create secret tls sample-app-tls \
    --key privkey1.pem \
    --cert fullchain1.pem
```
