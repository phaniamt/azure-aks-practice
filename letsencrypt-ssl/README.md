

# Letsencrypt ssl 

- **Reference Documentation Links**

- https://github.com/phaniamt/certbot-azure

### Export envs

```
DOMAIN=example.com
DNS_RG=myrg

```

### Generate the ssl certificates

```
certbot certonly  -d *.${DOMAIN} -d ${DOMAIN} \
-a dns-azure --dns-azure-credentials /tmp/mycredentials.json \
--dns-azure-resource-group $DNS_RG \
--email ${EMAIL}
--non-interactive  \
--agree-tos
```

  
### Add the ssl to application-gateway

```
CERT_PASSWD="1234"

az login --service-principal -u $AZ_SERVICE_PRINCIPAL_NAME -p $AZ_SERVICE_PRINCIPAL_KEY --tenant $AZ_TENANT

openssl pkcs12 -export -out $RENEWED_LINEAGE/pkcs12_cert.pfx -inkey $RENEWED_LINEAGE/privkey.pem -in $RENEWED_LINEAGE/cert.pem -certfile $RENEWED_LINEAGE/chain.pem -password pass:$CERT_PASSWD

az network application-gateway ssl-cert update -n $AZURE_CERT_NAME --gateway-name $AZURE_APP_GW_RESOURCE_NAME -g $AZURE_APP_GW_RESOURCE_GROUP_NAME --cert-file "$RENEWED_LINEAGE/pkcs12_cert.pfx" --cert-password $CERT_PASSWD
```
