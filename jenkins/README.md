### Create a docker network

```
docker network create nginx
```

### Get the token for serviceaccount

```
kubectl get secret $(kubectl get serviceaccount jenkins -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode
```

### Replace this token in kube config file
