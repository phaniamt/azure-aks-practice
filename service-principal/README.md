# Create  service-principal and give access to resource group

### Export envs

```
RG_NAME=aks-rg
SERVICE_PRINCIPAL_NAME=aks-service-principal
```

### Create a service-principal and give access to existing resource group

```
AKS_RG_ID=$(az group show --name aks-rg --query id -o tsv)
AKS_SP_PASSWD=$(az ad sp create-for-rbac --name http://$SERVICE_PRINCIPAL_NAME --skip-assignment --query password --output tsv)
AKS_SP_APP_ID=$(az ad sp show --id http://$SERVICE_PRINCIPAL_NAME --query appId --output tsv)

echo "AKS principal ID: $AKS_SP_APP_ID"
echo "AKS principal password: $AKS_SP_PASSWD"
```
### Assign the role to service-principal 
```
az role assignment create --role "Owner"  --assignee $AKS_SP_APP_ID --resource-group $RG_NAME
```
