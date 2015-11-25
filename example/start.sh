#!/bin/bash

# default
export COMPOSE_PROJECT_NAME=nginx
source common.sh

export CONTAINERBUDDY="$(cat ../etc/containerbuddy.json)"
export NGINX_CONF="$(cat ./nginx.ctmpl)"

docker-compose up -d

consoles() {
    local CONSUL=$(getIpPort consul 8500)
    local NGINX=$(getIpPort nginx 80)

    echo 'Opening Consul console...'
    open http://${CONSUL}/ui/
    echo 'Opening web page... the page will reload every 5 seconds with any updates.'
    open http://${NGINX}/app/
}

consoles
