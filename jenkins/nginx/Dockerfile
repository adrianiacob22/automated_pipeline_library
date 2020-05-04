FROM nginx:1.17.9
LABEL maintainer="adrianiacob22@gmail.com"
ENV nginx_conf /etc/nginx/conf.d/

## Cleanup default nginx conf file and create ssl directory
RUN rm /etc/nginx/conf.d/default.conf

## Adding custom nginx configuration files
COPY conf/jenkins.conf ${nginx_conf}
COPY conf/nginx.conf /etc/nginx/

EXPOSE 80 443
CMD ["nginx"]
