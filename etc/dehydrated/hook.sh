#!/usr/bin/env bash
CONSUL_HOST_DEFAULT="localhost"
if [ "${CONSUL_AGENT}" = "" -a "${CONSUL}" != "" ]; then
    CONSUL_HOST_DEFAULT=${CONSUL}
fi
CONSUL_HOST=${CONSUL_HOST:-$CONSUL_HOST_DEFAULT}
CONSUL_ROOT="http://${CONSUL_HOST}:8500/v1/kv/nginx"
CHALLENGE_PATH="/.well-known/acme-challenge"

function deploy_challenge {
    local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"

    curl -sX PUT -d "${TOKEN_FILENAME}" ${CONSUL_ROOT}/acme/challenge/token-filename | log
    test ${PIPESTATUS[0]} -eq 0 || (log "${FUNCNAME} failed" && return)
    curl -sX PUT -d "${TOKEN_VALUE}" ${CONSUL_ROOT}/acme/challenge/token-value | log
    test ${PIPESTATUS[0]} -eq 0 || (log "${FUNCNAME} failed" && return)

    # verify all nginx containers are responding with challenge before continuing
    # TODO: this is currently only looking at localhost
    RETRIES=0
    printf " + Waiting for challenge to be deployed..."
    while [ "$(curl -s --header \"HOST: ${DOMAIN}\" http://localhost${CHALLENGE_PATH}/${TOKEN_FILENAME})" != "${TOKEN_VALUE}" -a $RETRIES -lt 6 ]; do
        RETRIES=$((RETRIES+1))
        printf "."
        sleep 2
    done
    echo
}

function clean_challenge {
    local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"

    curl -sX DELETE ${CONSUL_ROOT}/acme/challenge/token-filename | log
    test ${PIPESTATUS[0]} -eq 0 || (log "${FUNCNAME} failed" && return)
    curl -sX DELETE ${CONSUL_ROOT}/acme/challenge/token-value | log
    test ${PIPESTATUS[0]} -eq 0 || (log "${FUNCNAME} failed" && return)
    curl -sX PUT -d "${TOKEN_FILENAME}" ${CONSUL_ROOT}/acme/challenge/last-token-filename | log
    test ${PIPESTATUS[0]} -eq 0 || (log "${FUNCNAME} failed" && return)
}

function deploy_cert {
    local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}" TIMESTAMP="${6}"

    curl -sX PUT -d "$(cat ${KEYFILE})" ${CONSUL_ROOT}/acme/key | log
    test ${PIPESTATUS[0]} -eq 0 || (log "${FUNCNAME} failed" && return)
    curl -sX PUT -d "$(cat ${CERTFILE})" ${CONSUL_ROOT}/acme/cert | log
    test ${PIPESTATUS[0]} -eq 0 || (log "${FUNCNAME} failed" && return)
    curl -sX PUT -d "$(cat ${CHAINFILE})" ${CONSUL_ROOT}/acme/chain | log
    test ${PIPESTATUS[0]} -eq 0 || (log "${FUNCNAME} failed" && return)
    curl -sX PUT -d "$(cat ${FULLCHAINFILE})" ${CONSUL_ROOT}/acme/fullchain | log
    test ${PIPESTATUS[0]} -eq 0 || (log "${FUNCNAME} failed" && return)
    curl -sX PUT -d "${TIMESTAMP}" ${CONSUL_ROOT}/acme/timestamp | log
    test ${PIPESTATUS[0]} -eq 0 || (log "${FUNCNAME} failed" && return)
    curl -sX PUT -d "$(date +%s)" ${CONSUL_ROOT}/acme/touched | log
    test ${PIPESTATUS[0]} -eq 0 || (log "${FUNCNAME} failed" && return)
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
