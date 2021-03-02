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
  
