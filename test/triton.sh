#!/bin/bash
set -e

export GIT_BRANCH="${GIT_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}"
export TAG="${TAG:-branch-$(basename "$GIT_BRANCH")}"
export COMPOSE_PROJECT="${COMPOSE_PROJECT_NAME:-nginx}"
export COMPOSE_FILE="${COMPOSE_FILE:-./examples/triton/docker-compose.yml}"

project="$COMPOSE_PROJECT"
manifest="$COMPOSE_FILE"

fail() {
    echo
    echo '------------------------------------------------'
    echo 'FAILED'
    echo "$1"
    exit 1
}

pass() {
    teardown
    echo
    echo '------------------------------------------------'
    echo 'PASSED!'
    echo
    exit 0
}

function finish {
    result=$?
    if [ $result -ne 0 ]; then fail "unexpected error"; fi
    pass
}
trap finish EXIT



# --------------------------------------------------------------------
# Helpers

# asserts that the container is running and marked as Up by Triton.
# fails after the timeout.
wait_for_containers() {
    local container count timeout i got
    container="$1"
    count="$2"
    timeout="${3:-60}" # default 60sec
    i=0
    echo "waiting for $container to be Up..."
    while [ $i -lt "$timeout" ]; do
        got=$(triton-compose -p "$project" -f "$manifest" ps "$container" | grep -c "Up")
        if [ "$got" -eq "$count" ]; then
            echo "$container reported Up in <= $i seconds"
            return
        fi
        i=$((i+1))
        sleep 1
    done
    fail "waited for container $container for $timeout seconds but it was not marked 'Up'"
}


# asserts that the application has registered at least n instances with
# Consul. fails after the timeout.
wait_for_service() {
    local service count timeout i got consul_ip
    service="$1"
    count="$2"
    timeout="${3:-30}" # default 30sec
    i=0
    echo "waiting for $count instances of $service to be registered with Consul..."
    consul_ip=$(triton ip "${project}_consul_1")
    while [ $i -lt "$timeout" ]; do
        got=$(curl -s "http://${consul_ip}:8500/v1/health/service/${service}?passing" \
                     | json -a Service.Address | wc -l | tr -d ' ')
        if [ "$got" -eq "$count" ]; then
            echo
            "$service registered in <= $i seconds"
            return
        fi
        i=$((i+1))
        sleep 1
    done
    fail "waited for service $service for $timeout seconds but it was not registed with Consul"
}

check_nginx_upstream_matches() {
    local service count timeout i ips got consul_ip

    service="$1"
    count="$2"
    timeout="${3:-30}" # default 30sec
    i=0
    echo "waiting for $count instances of $service to be in Nginx upstream..."
    consul_ip=$(triton ip "${project}_consul_1")
    while [ $i -lt "$timeout" ]; do
        ips=$(curl -s "http://${consul_ip}:8500/v1/health/service/${service}?passing" \
                     | json -a Service.Address | sort)
        ip_count=$(echo "$ips" | wc -l | tr -d ' ')
        if [ "$ip_count" -eq "$count" ]; then
            got=$(triton-docker exec "${project}_nginx_1" \
                                cat /etc/nginx/conf.d/site.conf \
                         | grep 3001 | tr -d 'serv ' | cut -d':' -f1 | sort)
            if [[ "$ips" == "$got" ]]; then
                echo "settled in <= $i seconds"
                return
            fi
        fi
        i=$((i+1))
        sleep 1
    done
    echo
    fail "waited for service $service for $timeout seconds but Nginx did not register upstreams. expected: ${ips} but got: ${got}"
}


netsplit() {
    echo "netsplitting ${project}_$1"
    triton-docker exec "${project}_$1" ifconfig eth0 down
}

heal() {
    echo "healing netsplit for ${project}_$1"
    triton-docker exec "${project}_$1" ifconfig eth0 up
}


# --------------------------------------------------------------------
# Test sections

profile() {
    echo
    echo '------------------------------------------------'
    echo 'setting up profile for tests'
    echo '------------------------------------------------'
    echo
    export TRITON_PROFILE="${TRITON_PROFILE:-us-east-1}"
    set +e
    # if we're already set up for Docker this will fail noisily
    triton profile docker-setup -y "$TRITON_PROFILE" > /dev/null 2>&1
    set -e
    triton profile set-current "$TRITON_PROFILE"
    eval "$(triton env)"

    # print out for profile debugging
    env | grep DOCKER
    env | grep SDC
    env | grep TRITON
}

run() {
    echo
    echo '------------------------------------------------'
    echo 'standing up initial test targets'
    echo '------------------------------------------------'
    echo
    triton-compose -p "$project" -f "$manifest" up -d
    wait_for_containers 'consul' 1
    wait_for_containers 'nginx' 1
    wait_for_containers 'backend' 1
    wait_for_service 'nginx' 1
    wait_for_service 'nginx-public' 1
    wait_for_service 'backend' 1
}

teardown() {
    echo
    echo '------------------------------------------------'
    echo 'tearing down containers'
    echo '------------------------------------------------'
    echo
    triton-compose -p "$project" -f "$manifest" stop
    triton-compose -p "$project" -f "$manifest" rm -f
}

scale() {
    echo
    echo '------------------------------------------------'
    echo 'scaling up backends'
    echo '------------------------------------------------'
    echo
    triton-compose -p "$project" -f "$manifest" scale backend=2
    wait_for_containers 'backend' 2
    wait_for_service 'backend' 2
}

test-netsplit() {
    echo
    echo '------------------------------------------------'
    echo 'executing netsplit test'
    echo '------------------------------------------------'
    echo
    check_nginx_upstream_matches backend 2
    netsplit "backend_1"
    check_nginx_upstream_matches backend 1
    heal "backend_1"
    check_nginx_upstream_matches backend 2
}


# --------------------------------------------------------------------
# Main loop

profile
run
scale
test-netsplit
