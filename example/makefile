MAKEFLAGS += --warn-undefined-variables
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail
.DEFAULT_GOAL := build

PHONY: *

# build image locally
build:
	@docker-compose -p nginx stop || true
	@docker-compose -p nginx rm -f || true
	docker-compose -p nginx -f local-compose.yml build

# test against Docker locally
test:
	@docker-compose -p nginx stop || true
	@docker-compose -p nginx rm -f || true
	./start.sh -p nginx -f local-compose.yml

# run example app on Triton
run:
	./start.sh -p nginx

# build and send up to the Docker Hub
ship:
	cd .. && docker build -t="0x74696d/triton-nginx" .
	docker push 0x74696d/triton-nginx
