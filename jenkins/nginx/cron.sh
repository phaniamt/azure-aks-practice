#!/bin/bash
source /env
while read d; do
echo " Generating the SSL certificates for ${d} "
certbot certonly \
--webroot -w /var/www/certbot \
--email ${EMAIL} \
-d ${d} \
--rsa-key-size 4096 \
--non-interactive  \
--agree-tos \
--force-renewal
echo " SSL certificates generated successfully for ${d} at $(date) "
done </opt/domains.txt
echo " Restarting the Nginx "
service nginx restart
echo " Nginx restarted sucessfully "
