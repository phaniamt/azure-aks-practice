#!/bin/bash
# Edit export statements to make any changes required as per your environment
# Execute below export statements
AKS_RESOURCE_GROUP=aks-rg
AKS_REGION=centralus
echo $AKS_RESOURCE_GROUP, $AKS_REGION

# Create Resource Group
az group create --location ${AKS_REGION} \
                --name ${AKS_RESOURCE_GROUP}

# Create vnet

AKS_VNET=aks-vnet
AKS_VNET_ADDRESS_PREFIX=10.0.0.0/8
AKS_VNET_SUBNET_DEFAULT=aks-subnet-default
AKS_VNET_SUBNET_DEFAULT_PREFIX=10.240.0.0/16
AKS_VNET_SUBNET_APPGW=aks-subnet-appgw
AKS_VNET_SUBNET_APPGW_PREFIX=10.241.0.0/16

# Create Virtual Network & default Subnet
az network vnet create -g ${AKS_RESOURCE_GROUP} \
                       -n ${AKS_VNET} \
                       --address-prefix ${AKS_VNET_ADDRESS_PREFIX} \
                       --subnet-name ${AKS_VNET_SUBNET_DEFAULT} \
                       --subnet-prefix ${AKS_VNET_SUBNET_DEFAULT_PREFIX} \
                       --location ${AKS_REGION}

# Create APPGW Subnet in Virtual Network
az network vnet subnet create \
    --resource-group ${AKS_RESOURCE_GROUP} \
    --vnet-name ${AKS_VNET} \
    --name ${AKS_VNET_SUBNET_APPGW} \
    --address-prefixes ${AKS_VNET_SUBNET_APPGW_PREFIX}




# Get Virtual Network default subnet id
AKS_VNET_SUBNET_DEFAULT_ID=$(az network vnet subnet show \
                           --resource-group ${AKS_RESOURCE_GROUP} \
                           --vnet-name ${AKS_VNET} \
                           --name ${AKS_VNET_SUBNET_DEFAULT} \
                           --query id \
                           -o tsv)
echo ${AKS_VNET_SUBNET_DEFAULT_ID}


# Create Folder
mkdir $HOME/.ssh/aks-sshkeys

# Create SSH Key . if exist overwrite
ssh-keygen -f ~/.ssh/aks-sshkeys/sshkey -q -N "" <<<y 2>&1 >/dev/null
# List Files
ls -lrt $HOME/.ssh/aks-sshkeys

# Set SSH KEY Path
AKS_SSH_KEY_LOCATION=${HOME}/.ssh/aks-sshkeys/sshkey.pub
echo $AKS_SSH_KEY_LOCATION

# Create Log Analytics Workspace
AKS_MONITORING_LOG_ANALYTICS_WORKSPACE_ID=$(az monitor log-analytics workspace create   --resource-group ${AKS_RESOURCE_GROUP} \
                                           --workspace-name aks-loganalytics-my-workspace --location $AKS_REGION\
                                           --query id \
                                           -o tsv)

echo $AKS_MONITORING_LOG_ANALYTICS_WORKSPACE_ID

ACR_NAME=myacr

az acr create --name $ACR_NAME --resource-group ${AKS_RESOURCE_GROUP} --sku Standard --location ${AKS_REGION}

az acr import  -n $ACR_NAME --source docker.io/library/nginx:1.19.0 --image nginx:1.19.0

# List Kubernetes Versions available as on today
az aks get-versions --location ${AKS_REGION} -o table

# Set Cluster Name
AKS_CLUSTER=akscluster
echo $AKS_CLUSTER

# Upgrade az CLI  (To latest version)
az --version
az upgrade

# Create AKS cluster
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

# Configure Credentials
az aks get-credentials --name ${AKS_CLUSTER}  --resource-group ${AKS_RESOURCE_GROUP} --overwrite-existing

# Cluster Info
kubectl cluster-info

# List Node Pools
az aks nodepool list --cluster-name ${AKS_CLUSTER} --resource-group ${AKS_RESOURCE_GROUP} -o table

# Check the current kubernetes-version

az aks show --resource-group ${AKS_RESOURCE_GROUP} --name ${AKS_CLUSTER} --query kubernetesVersion --output table

# List which pods are running in system nodepool from kube-system namespace
kubectl get pod -o=custom-columns=NODE-NAME:.spec.nodeName,POD-NAME:.metadata.name -n kube-system


# Get the MSI of our AKS cluster
az aks show -g ${AKS_RESOURCE_GROUP} -n ${AKS_CLUSTER} --query "identity"


APPGW_SUBNET_ID=$(az network vnet subnet show --resource-group $AKS_RESOURCE_GROUP --vnet-name $AKS_VNET --name $AKS_VNET_SUBNET_APPGW --query id -o tsv)



# https://docs.microsoft.com/en-us/azure/aks/cluster-autoscaler

# Ref: https://docs.microsoft.com/en-us/azure/application-gateway/tutorial-ingress-controller-add-on-new

#az extension add --name aks-preview

#az feature register --name AKS-IngressApplicationGatewayAddon --namespace Microsoft.ContainerService

#az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AKS-IngressApplicationGatewayAddon')].{Name:name,State:properties.state}"

#az provider register --namespace Microsoft.ContainerService


kubectl create ns web-server

kubens web-server

APPGW_NAME=myappgw

az aks enable-addons --name ${AKS_CLUSTER} --resource-group ${AKS_RESOURCE_GROUP} --addons ingress-appgw --appgw-subnet-id $APPGW_SUBNET_ID --appgw-name $APPGW_NAME --appgw-watch-namespace web-server,default

##################################################

az network application-gateway ssl-cert list -g MC_${AKS_RESOURCE_GROUP}_${AKS_CLUSTER}_${AKS_REGION} --gateway-name ${APPGW_NAME}

#https://medium.com/@t.tak/build-https-support-load-balancer-on-azure-81e111e58d98

#https://github.com/rseidt/certbot-azure/blob/master/docker/update-ssl-cert.sh

CERT_PASSWD=1234
#/ pem to pfx
openssl pkcs12 -export -out certificate.pfx -inkey privkey1.pem -in fullchain1.pem -password pass:$CERT_PASSWD
#// pem to cer
openssl x509 -inform PEM -in fullchain1.pem -outform DER -out certificate.cer

CERT_NAME=myssl

az network application-gateway ssl-cert create -g MC_${AKS_RESOURCE_GROUP}_${AKS_CLUSTER}_${AKS_REGION} --gateway-name $APPGW_NAME \
    -n $CERT_NAME --cert-file certificate.pfx --cert-password $CERT_PASSWD

az network application-gateway ssl-cert list -g MC_${AKS_RESOURCE_GROUP}_${AKS_CLUSTER}_${AKS_REGION} --gateway-name ${APPGW_NAME}

az network application-gateway ssl-cert show  -g MC_${AKS_RESOURCE_GROUP}_${AKS_CLUSTER}_${AKS_REGION} --gateway-name ${APPGW_NAME} -n $CERT_NAME

# https://github.com/Azure/application-gateway-kubernetes-ingress/tree/master/docs/examples/sample-app

# https://azure.github.io/application-gateway-kubernetes-ingress/annotations/#ssl-redirect

# https://azure.github.io/application-gateway-kubernetes-ingress/features/appgw-ssl-certificate/


# 2 nd method for add the ssl

kubectl create secret tls sample-app-tls \
    --key privkey1.pem \
    --cert fullchain1.pem


