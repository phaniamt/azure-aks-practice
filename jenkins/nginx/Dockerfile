FROM ubuntu:16.04
RUN apt-get update
RUN apt-get -y install software-properties-common
RUN add-apt-repository ppa:nginx/stable
RUN apt-get update && apt-get install -y iputils-ping
RUN apt-get update && apt-get install -y curl vim
RUN apt-get update && \
    apt-get -y install nginx
RUN mkdir -p /etc/letsencrypt && mkdir -p /var/www/certbot
COPY nginx.conf /etc/nginx/nginx.conf
#COPY default /etc/nginx/sites-available/default
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log
COPY virtual-hosts.com /etc/nginx/sites-available/virtual-hosts.com
RUN ln -s /etc/nginx/sites-available/virtual-hosts.com /etc/nginx/sites-enabled/virtual-hosts.com
# Install certbot
RUN apt-get update && add-apt-repository universe && add-apt-repository ppa:certbot/certbot
RUN apt-get update && apt-get install certbot -y
# Install cron
RUN apt-get update && apt-get -y install cron
ADD cronjobs /etc/cron.d/cronjobs
RUN crontab /etc/cron.d/cronjobs
RUN chmod 0644 /etc/cron.d/cronjobs
RUN touch /var/log/cron.log
COPY cron.sh /opt/
COPY domains.txt /opt/
EXPOSE 80 443
#CMD ["nginx", "-g", "daemon off;"]
CMD [ "sh", "-c", "printenv > /env && nginx && cron -f" ]
