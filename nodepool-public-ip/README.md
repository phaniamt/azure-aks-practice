# Enable public ip feature for nodepools

### Enable public ip for aks nodes

```
az extension add --name aks-preview
az extension update --name aks-preview
az extension list
```

### Register the public ip feature

```
az feature register --name NodePublicIPPreview --namespace Microsoft.ContainerService

az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/NodePublicIPPreview')].{Name:name,State:properties.state}"
```

### Export envs

```
AKS_RESOURCE_GROUP=aks-rg
AKS_REGION=centralus
echo $AKS_RESOURCE_GROUP, $AKS_REGION
AKS_CLUSTER=akscluster
echo $AKS_CLUSTER
```

### Add the new nodepool with --enable-node-public-ip

```
az aks nodepool add --resource-group ${AKS_RESOURCE_GROUP} \
                    --cluster-name ${AKS_CLUSTER} \
                    --kubernetes-version 1.18.10 \
                    --name appspool \
                    --node-count 1 \
                    --enable-cluster-autoscaler \
                    --max-count 2 \
                    --min-count 1 \
                    --mode User \
                    --node-osdisk-size 30 \
                    --node-vm-size Standard_DS1_v2 \
                    --os-type Linux \
                    --labels nodepool-type=user  nodepoolos=linux server=apps \
                    --tags nodepool-type=user  nodepoolos=linux server=apps \
                    --enable-node-public-ip \
                    --zones {1,2,3}
					
```					

- **Reference Documentation Links**

- https://docs.microsoft.com/en-us/azure/aks/use-multiple-node-pools
