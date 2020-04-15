FROM nginx:1.17.9
LABEL maintainer="adrian.iacob@ro.ibm.com"
ENV nginx_conf /etc/nginx/conf.d/
ENV nginx_ssl  /etc/nginx/ssl/


## Cleanup default nginx conf file and create ssl directory
RUN rm /etc/nginx/conf.d/default.conf && \
    mkdir ${nginx_ssl}

## Adding custom nginx configuration files
COPY conf/jenkins.conf ${nginx_conf}
COPY conf/nginx.conf /etc/nginx/

## Adding nginx certificates
COPY certs/server.* ${nginx_ssl}

EXPOSE 80 443
CMD ["nginx"]
