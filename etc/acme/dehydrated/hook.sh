#!/usr/bin/env bash
set -o pipefail

SERVICE_NAME=${SERVICE_NAME:-nginx}
CONSUL_HOST_DEFAULT=${CONSUL:-consul}
if [ "${CONSUL_AGENT}" != "" ]; then
    CONSUL_HOST_DEFAULT="localhost"
fi
CONSUL_HOST=${CONSUL_HOST:-$CONSUL_HOST_DEFAULT}
CONSUL_ROOT="http://${CONSUL_HOST}:8500/v1"
CONSUL_KEY_ROOT="${CONSUL_ROOT}/kv/${SERVICE_NAME}"
CHALLENGE_PATH="/.well-known/acme-challenge"

function deploy_challenge {
    local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"
    local TOKEN_DEPLOY_RETRY_LIMIT=6

    (curl -sX PUT -d "${TOKEN_FILENAME}" ${CONSUL_KEY_ROOT}/acme/challenge/token-filename | log \
        && curl -sX PUT -d "${TOKEN_VALUE}" ${CONSUL_KEY_ROOT}/acme/challenge/token-value | log \
    ) || (log "${FUNCNAME} failed"; return 1)

    # verify all nginx containers are responding with challenge before continuing
    local NGINX_INSTANCES=$(curl -s "${CONSUL_ROOT}/catalog/service/nginx" | jq -Mr '.[].ServiceAddress')
    local NGINX_INSTANCE_COUNT=$(echo "${NGINX_INSTANCES}" | wc -l)
    local RETRIES=0
    local MATCHING=0
    printf " + Waiting for challenge to be deployed..."
    while [ $RETRIES -lt $TOKEN_DEPLOY_RETRY_LIMIT -a $MATCHING -lt $NGINX_INSTANCE_COUNT ]; do
        MATCHING=0
        for NGINX_INSTANCE_HOST in $NGINX_INSTANCES; do
            if [ "$(curl -s --header \"HOST: ${DOMAIN}\" http://${NGINX_INSTANCE_HOST}${CHALLENGE_PATH}/${TOKEN_FILENAME})" = "${TOKEN_VALUE}" ]; then
                MATCHING=$((MATCHING+1))
            fi
        done
        RETRIES=$((RETRIES+1))
        printf "."
        sleep 2
    done
    echo
}

function clean_challenge {
    local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"

    curl -sX DELETE ${CONSUL_KEY_ROOT}/acme/challenge/token-filename | log \
        && curl -sX DELETE ${CONSUL_KEY_ROOT}/acme/challenge/token-value | log \
        && curl -sX PUT -d "${TOKEN_FILENAME}" ${CONSUL_KEY_ROOT}/acme/challenge/last-token-filename | log \
        && return 0
    log "${FUNCNAME} failed"
    return 1
}

function deploy_cert {
    local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}" TIMESTAMP="${6}"

    curl -sX PUT -d "$(cat ${KEYFILE})" ${CONSUL_KEY_ROOT}/acme/key | log \
        && curl -sX PUT -d "$(cat ${CERTFILE})" ${CONSUL_KEY_ROOT}/acme/cert | log \
        && curl -sX PUT -d "$(cat ${CHAINFILE})" ${CONSUL_KEY_ROOT}/acme/chain | log \
        && curl -sX PUT -d "$(cat ${FULLCHAINFILE})" ${CONSUL_KEY_ROOT}/acme/fullchain | log \
        && curl -sX PUT -d "${TIMESTAMP}" ${CONSUL_KEY_ROOT}/acme/timestamp | log \
        && curl -sX PUT -d "$(date +%s)" ${CONSUL_KEY_ROOT}/acme/touched | log \
        && return 0
    log "${FUNCNAME} failed"
    return 1
}

function unchanged_cert {
    local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}"
}

function log {
    if [ -n "$1" ]; then
        IN="$1"
    else
        read IN
    fi

    if [ "${IN}" != "true" ]; then
        echo "    - ${IN}"
    fi
}

HANDLER=$1; shift; $HANDLER $@
