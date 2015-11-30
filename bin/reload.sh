#!/bin/bash

SERVICE_NAME=${SERVICE_NAME:-nginx}

if [ -z "${NGINX_CONF}" ]; then
    # fetch latest Nginx configuration template from Consul k/v
    curl -s --fail consul:8500/v1/kv/${SERVICE_NAME}/template?raw > /tmp/nginx.ctmpl
else
    # dump the ${NGINX_CONF} environment variable as a file
    # the quotes are important here to preserve newlines!
    echo "${NGINX_CONF}" > /tmp/nginx.ctmpl
fi

# render Nginx configuration template using values from Consul,
# then gracefully reload Nginx
consul-template \
    -once \
    -consul consul:8500 \
    -template "/tmp/nginx.ctmpl:/etc/nginx/nginx.conf:nginx -s reload || true"
