#!/bin/bash

# default
export COMPOSE_PROJECT_NAME=nginx
source common.sh

export CONTAINERBUDDY="$(cat ../etc/containerbuddy.json)"
export NGINX_CONF="$(cat ./nginx.ctmpl)"

docker-compose up -d

# poll Consul for liveness and then open the console
poll-for-page "http://$(getIpPort consul 8500)/ui/" \
              'Waiting for Consul...' \
              'Opening Consul console... Refresh the page to watch services register.'

# poll Nginx for liveness and then open the page
poll-for-page "http://$(getIpPort nginx 80)/app/" \
              'Waiting for application to register as healthy...' \
              'Opening web page... The page will reload every 5 seconds with any updates.'
