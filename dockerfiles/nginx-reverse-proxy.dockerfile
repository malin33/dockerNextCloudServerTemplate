FROM nginx:stable-alpine

COPY nginx-reverse-proxy/conf/default.conf.template /etc/nginx/templates/default.conf.template

RUN rm /var/log/nginx/*.log

CMD ["nginx", "-g", "daemon off;"]
