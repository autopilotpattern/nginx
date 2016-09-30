#!/usr/bin/env bash

CONSUL_ROOT="http://localhost:8500/v1/kv/nginx"
CHALLENGE_PATH="/.well-known/acme-challenge"

function deploy_challenge {
    local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"

    curl -sX PUT -d "${TOKEN_FILENAME}" ${CONSUL_ROOT}/domains/${DOMAIN}/acme/challenge/token-filename > /dev/null
    curl -sX PUT -d "${TOKEN_VALUE}" ${CONSUL_ROOT}/domains/${DOMAIN}/acme/challenge/token-value > /dev/null

    # for each domain verify all nginx containers are responding with challenge before continuing
    # TODO: this is currently only looking at localhost
    printf " + Waiting for challenge to be deployed..."
    while [ "$(curl -s --header \"HOST: ${DOMAIN}\" http://localhost${CHALLENGE_PATH}/${TOKEN_FILENAME})" != "${TOKEN_VALUE}" ]; do
        printf "."
        sleep 2
    done
    echo
}

function clean_challenge {
    local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"

    curl -sX DELETE ${CONSUL_ROOT}/domains/${DOMAIN}/acme/challenge/token-filename > /dev/null
    curl -sX DELETE ${CONSUL_ROOT}/domains/${DOMAIN}/acme/challenge/token-value > /dev/null
    curl -sX PUT -d "${TOKEN_FILENAME}" ${CONSUL_ROOT}/domains/${DOMAIN}/acme/challenge/last-token-filename > /dev/null
}

function deploy_cert {
    local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}" TIMESTAMP="${6}"

    curl -sX PUT -d "$(cat ${KEYFILE})" ${CONSUL_ROOT}/domains/${DOMAIN}/acme/key > /dev/null
    curl -sX PUT -d "$(cat ${CERTFILE})" ${CONSUL_ROOT}/domains/${DOMAIN}/acme/cert > /dev/null
    curl -sX PUT -d "$(cat ${CHAINFILE})" ${CONSUL_ROOT}/domains/${DOMAIN}/acme/chain > /dev/null
    curl -sX PUT -d "$(cat ${FULLCHAINFILE})" ${CONSUL_ROOT}/domains/${DOMAIN}/acme/fullchain > /dev/null
    curl -sX PUT -d "${TIMESTAMP}" ${CONSUL_ROOT}/domains/${DOMAIN}/acme/timestamp > /dev/null
    curl -sX PUT -d "$(date +%s)" ${CONSUL_ROOT}/domains/${DOMAIN}/acme/touched > /dev/null
}

function unchanged_cert {
    local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}"
}

HANDLER=$1; shift; $HANDLER $@
