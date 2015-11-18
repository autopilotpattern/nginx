#!/bin/bash

# check for prereqs
command -v docker >/dev/null 2>&1 || { echo "Docker is required, but does not appear to be installed. See https://docs.joyent.com/public-cloud/api-access/docker"; exit; }
command -v sdc-listmachines >/dev/null 2>&1 || { echo "Joyent CloudAPI CLI is required, but does not appear to be installed. See https://apidocs.joyent.com/cloudapi/#getting-started"; exit; }
command -v json >/dev/null 2>&1 || { echo "JSON CLI tool is required, but does not appear to be installed. See https://apidocs.joyent.com/cloudapi/#getting-started"; exit; }

# default values which can be overriden by -f or -p flags
export COMPOSE_FILE=
export COMPOSE_PROJECT_NAME=consul

while getopts "f:p:" optchar; do
    case "${optchar}" in
        f) export COMPOSE_FILE=${OPTARG} ;;
        p) export COMPOSE_PROJECT_NAME=${OPTARG} ;;
    esac
done
shift $(expr $OPTIND - 1 )

# give the docker remote api more time before timeout
export DOCKER_CLIENT_TIMEOUT=300

echo 'Pulling latest container versions'
docker-compose pull

echo 'Starting Consul.'
docker-compose up -d consul

# get network info from consul and poll it for liveness
if [ -z "${COMPOSE_FILE}" ]; then
    CONSUL_IP=$(sdc-listmachines --name ${COMPOSE_PROJECT_NAME}_consul_1 | json -a ips.1)
else
    CONSUL_IP=${CONSUL_IP:-$(docker-machine ip default)}
fi

echo "Writing template values to Consul at ${CONSUL_IP}"
while :
do
    # we'll sometimes get an HTTP500 here if consul hasn't completed
    # it's leader election on boot yet, so poll till we get a good response.
    sleep 1
    curl --fail -s -X PUT --data-binary @./default.ctmpl \
         http://${CONSUL_IP}:8500/v1/kv/nginx/template && break
    echo -ne .
done
echo
echo 'Opening consul console'
open http://${CONSUL_IP}:8500/ui

echo 'Starting application servers and Nginx'
CONTAINERBUDDY=$(cat ../config/containerbuddy/nginx.json) docker-compose up -d

# get network info from Nginx and poll it for liveness
if [ -z "${COMPOSE_FILE}" ]; then
    NGINX_IP=$(sdc-listmachines --name ${COMPOSE_PROJECT_NAME}_nginx_1 | json -a ips.1)
else
    NGINX_IP=${NGINX_IP:-$(docker-machine ip default)}
fi
NGINX_PORT=$(docker inspect --format='{{(index (index .NetworkSettings.Ports "80/tcp") 0).HostPort}}' ${COMPOSE_PROJECT_NAME}_nginx_1)
echo "Waiting for Nginx at ${NGINX_IP}:${NGINX_PORT} to pick up initial configuration."
while :
do
    sleep 1
    curl -s --fail -o /dev/null "http://${NGINX_IP}:${NGINX_PORT}/app/" && break
    echo -ne .
done
echo
echo 'Opening web page... the page will reload every 5 seconds with any updates.'
open http://${NGINX_IP}:${NGINX_PORT}/app/

echo 'Try scaling up the app!'
echo "docker-compose scale app=3"
