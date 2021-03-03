# aks kubernets service create with static ip

### Export envs

```
AKS_RESOURCE_GROUP=aks-rg
AKS_REGION=centralus
echo $AKS_RESOURCE_GROUP, $AKS_REGION
AKS_CLUSTER=akscluster
echo $AKS_CLUSTER
IP_NAME=myAKSPublicIP
```

### Create the public-ip

```
az network public-ip create \
    --resource-group MC_${AKS_RESOURCE_GROUP}_${AKS_CLUSTER}_${AKS_REGION} \
    --name $IP_NAME \
    --sku Standard \
    --allocation-method static
```

### Show the public-ip

```
az network public-ip show --resource-group MC_${AKS_RESOURCE_GROUP}_${AKS_CLUSTER}_${AKS_REGION} --name $IP_NAME --query ipAddress --output tsv
```


### Create the service with static public-ip	

```	
apiVersion: v1
kind: Service
metadata:
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-resource-group: myResourceGroup
  name: azure-load-balancer
spec:
  loadBalancerIP: 52.165.218.49
  type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: azure-load-balancer
```

- **Reference Documentation Links**

- https://docs.microsoft.com/en-us/azure/aks/static-ip
