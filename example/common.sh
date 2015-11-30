#!/bin/bash
set -e -o pipefail

# check for prereqs
check() {
    command -v docker >/dev/null 2>&1 || {
        echo "Docker is required, but does not appear to be installed. See https://docs.joyent.com/public-cloud/api-access/docker"; exit; }
    command -v sdc-listmachines >/dev/null 2>&1 || {
        echo "Joyent CloudAPI CLI is required, but does not appear to be installed. See https://apidocs.joyent.com/cloudapi/#getting-started"; exit; }
    command -v json >/dev/null 2>&1 || {
        echo "JSON CLI tool is required, but does not appear to be installed. See https://apidocs.joyent.com/cloudapi/#getting-started"; exit; }
}

usage() {
    echo 'Usage ./start.sh [-f docker-compose.yml] [-p project]'
    echo
    echo 'Starts up the entire stack.'
    echo
    echo '-f <filename> [optional] use this file as the docker-compose config file'
    echo '-p <project>  [optional] use this name as the project prefix for docker-compose'
    echo '-h            help. print this thing you are reading now.'
}

prep() {
    echo "Starting example application"
    echo "project prefix:      $COMPOSE_PROJECT_NAME"
    echo "docker-compose file: $COMPOSE_FILE"
}

# get the IP:port of a container via either the local docker-machine or from
# sdc-listmachines.
getIpPort() {
    if [ -z "${COMPOSE_FILE}" ]; then
        local ip=$(sdc-listmachines --name ${COMPOSE_PROJECT_NAME}_$1_1 | json -a ips.1)
        local port=$2
    else
        local ip=$(docker-machine ip default)
        local port=$(docker inspect ${COMPOSE_PROJECT_NAME}_$1_1 | json -a NetworkSettings.Ports."$2/tcp".0.HostPort)
    fi
    echo "$ip:$port"
}

# usage: poll-for-page <url> <pre-message> <post-message>
poll-for-page() {
    echo "$2"
    while :
    do
        curl --fail -s -o /dev/null "$1" && break
        sleep 1
        echo -ne .
    done
    echo
    echo "$3"
    open "$1"
}

# default values which can be overriden by -f or -p flags
export COMPOSE_FILE=

while getopts "f:p:" optchar; do
    case "${optchar}" in
        f) export COMPOSE_FILE=${OPTARG} ;;
        p) export COMPOSE_PROJECT_NAME=${OPTARG} ;;
        h) usage; exit 0;;
    esac
done
shift $(expr $OPTIND - 1 )

# give the docker remote api more time before timeout
export DOCKER_CLIENT_TIMEOUT=300

cmd=$1
if [ ! -z "$cmd" ]; then
    shift 1
    $cmd "$@"
    exit
fi

check
prep
