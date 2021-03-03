#!/bin/bash
AKS_RESOURCE_GROUP=aks-rg
AKS_REGION=centralus
az group delete --name $AKS_RESOURCE_GROUP
