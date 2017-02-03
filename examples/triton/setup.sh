#!/bin/bash

# Check for correct configuration for running on Triton.
# Export environment variables for use with CNS name for Consul.

command -v docker >/dev/null 2>&1 || {
    echo
    echo 'Error! Docker is not installed!'
    echo 'See https://docs.joyent.com/public-cloud/api-access/docker'
    return
}
command -v triton >/dev/null 2>&1 || {
    echo
    echo 'Error! Joyent Triton CLI is not installed!'
    echo 'See https://www.joyent.com/blog/introducing-the-triton-command-line-tool'
    return
}

if [[ ! "true" == "$(triton account get | awk -F': ' '/cns/{print $2}')" ]]; then
    echo
    echo 'Error! Triton CNS is required and not enabled.'
    return
fi

# make sure Docker client is pointed to the same place as the Triton client

docker_user=$(docker info 2>&1 | awk -F": " '/SDCAccount:/{print $2}')
docker_dc=$(echo "${DOCKER_HOST}" | awk -F"/" '{print $3}' | awk -F'.' '{print $1}')
triton_user=$(triton profile get | awk -F": " '/account:/{print $2}')
triton_dc=$(triton profile get | awk -F"/" '/url:/{print $3}' | awk -F'.' '{print $1}')
triton_account=$(triton account get | awk -F": " '/id:/{print $2}')

if [ ! "$docker_user" = "$triton_user" ] || [ ! "$docker_dc" = "$triton_dc" ]; then
    echo
    echo 'Error! The Triton CLI configuration does not match the Docker CLI configuration.'
    echo "Docker user: ${docker_user}"
    echo "Triton user: ${triton_user}"
    echo "Docker data center: ${docker_dc}"
    echo "Triton data center: ${triton_dc}"
else
    export TRITON_DC="${triton_dc}"
    export TRITON_ACCOUNT="${triton_account}"
fi
