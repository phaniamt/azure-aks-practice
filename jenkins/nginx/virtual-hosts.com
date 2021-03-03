#################################################################################################
#                                          Jenkins                                              #
#################################################################################################


server {
    listen         443 ssl;
    listen       80;
    ssl_certificate    /etc/letsencrypt/live/jenkins.my.xyz/fullchain.pem;
    ssl_certificate_key    /etc/letsencrypt/live/jenkins.my.xyz/privkey.pem;
    server_name    jenkins.my.xyz;

    location / {
    resolver 127.0.0.11;
    set $target http://jenkins:8080;
    proxy_pass  $target;
    proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
    proxy_redirect off;
    proxy_buffering off;
    proxy_set_header        Host            $host;
    proxy_set_header        X-Real-IP       $remote_addr;
    proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
   }

    location /.well-known/acme-challenge/ {
    root /var/www/certbot;
      }
   # force https-redirects
    if ($scheme = http) {
        return 301 https://$host$request_uri;
    }
}
#################################################################################################
#                                          Rancher                                              #
#################################################################################################

server {
    listen         443 ssl;
    listen       80;
    ssl_certificate    /etc/letsencrypt/live/rancher.my.xyz/fullchain.pem;
    ssl_certificate_key    /etc/letsencrypt/live/rancher.my.xyz/privkey.pem;

    server_name    rancher.my.xyz;

    location / {
    resolver 127.0.0.11;
    proxy_pass  $target;
    set $target http://rancher;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Port $server_port;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    #This allows the ability for the execute shell window to remain open for up to 15 minutes. Without this parameter, the default is 1 minute and will automatically close.
    proxy_read_timeout 900s;
    proxy_buffering off;
    }
    location /.well-known/acme-challenge/ {
    root /var/www/certbot;
      }
   # force https-redirects
    if ($scheme = http) {
        return 301 https://$host$request_uri;
    }
}

##################################################################################################################
