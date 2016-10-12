#!/bin/bash

SERVICE_NAME=${SERVICE_NAME:-nginx}
CONSUL=${CONSUL:-consul}
CERT_DIR="/var/www/ssl"

# Render Nginx configuration template using values from Consul,
# but do not reload because Nginx has't started yet
preStart() {
    consul-template \
        -once \
        -dedup \
        -consul ${CONSUL}:8500 \
        -template "/etc/nginx/nginx.conf.ctmpl:/etc/nginx/nginx.conf"
}

# Render Nginx configuration template using values from Consul,
# then gracefully reload Nginx
onChange() {
    local SSL_READY="false"
    if [ -f ${CERT_DIR}/fullchain.pem -a -f ${CERT_DIR}/privkey.pem ]; then
        SSL_READY="true"
    fi
    export SSL_READY
    consul-template \
        -once \
        -dedup \
        -consul ${CONSUL}:8500 \
        -template "/etc/nginx/nginx.conf.ctmpl:/etc/nginx/nginx.conf:nginx -s reload"
}

help() {
    echo "Usage: ./reload.sh preStart  => first-run configuration for Nginx"
    echo "       ./reload.sh onChange  => [default] update Nginx config on upstream changes"
}

until
    cmd=$1
    if [ -z "$cmd" ]; then
        onChange
    fi
    shift 1
    $cmd "$@"
    [ "$?" -ne 127 ]
do
    onChange
    exit
done
