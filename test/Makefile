# Makefile for shipping and testing the container image.

MAKEFLAGS += --warn-undefined-variables
.DEFAULT_GOAL := build
.PHONY: *

# we get these from CI environment if available, otherwise from git
GIT_COMMIT ?= $(shell git rev-parse --short HEAD)
GIT_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)
WORKSPACE ?= $(shell pwd)/..

namespace ?= autopilotpattern
tag := branch-$(shell basename $(GIT_BRANCH))
image := $(namespace)/nginx
example := $(namespace)/nginx-example
backend := $(namespace)/nginx-backend
testImage := $(namespace)/nginx-testrunner

dockerLocal := DOCKER_HOST= DOCKER_TLS_VERIFY= DOCKER_CERT_PATH= docker

## Display this help message
help:
	@awk '/^##.*$$/,/[a-zA-Z_-]+:/' $(MAKEFILE_LIST) | awk '!(NR%2){print $$0p}{p=$$0}' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' | sort


# ------------------------------------------------
# Container builds

## Builds the application container image locally
build: test-runner
	cd .. && $(dockerLocal) build -t=$(image):$(tag) .

## Builds the application example images locally
examples: build
	cd .. && sed 's/latest/$(tag)/' examples/Dockerfile > examples/Examplefile
	cd .. && $(dockerLocal) build -f examples/Examplefile -t=$(example):$(tag) .
	cd .. && $(dockerLocal) build -f examples/backend/Dockerfile -t=$(backend):$(tag) .

## Build the test running container
test-runner:
	cd .. && $(dockerLocal) build -f test/Dockerfile -t=$(testImage):$(tag) .

## Push the current application container images to the Docker Hub
push:
	$(dockerLocal) push $(image):$(tag)

## Push the current example application container images to the Docker Hub
push-examples:
	$(dockerLocal) push $(example):$(tag)
	$(dockerLocal) push $(backend):$(tag)
	$(dockerLocal) push $(testImage):$(tag)

## Tag the current images as 'latest' and push them to the Docker Hub
ship:
	$(dockerLocal) tag $(image):$(tag) $(image):latest
	$(dockerLocal) tag $(testImage):$(tag) $(testImage):latest
	$(dockerLocal) tag $(image):$(tag) $(image):latest
	$(dockerLocal) push $(image):$(tag)
	$(dockerLocal) push $(image):latest



# ------------------------------------------------
# Test running

## Pull the container images from the Docker Hub
pull:
	docker pull $(image):$(tag)

## Pull the test target images from the docker Hub
pull-examples:
	docker pull $(example):$(tag)
	docker pull $(backend):$(tag)
	docker pull $(testImage):$(tag)


run-local:
	cd ../examples/compose && TAG=$(tag) docker-compose up -d

# Make keys available when running tests from a container
SDC_KEYS_VOL ?= -v $(DOCKER_CERT_PATH):$(DOCKER_CERT_PATH) -v $(HOME)/.ssh:/root.ssh

## Run the integration test runner. Runs locally but targets Triton.
test:
	$(call check_var, TRITON_ACCOUNT TRITON_DC, \
		required to run integration tests on Triton.)
	$(dockerLocal) run --rm \
		-e TAG=$(tag) \
		-e COMPOSE_HTTP_TIMEOUT=300 \
		-e DOCKER_HOST=$(DOCKER_HOST) \
		-e DOCKER_TLS_VERIFY=1 \
		-e DOCKER_CERT_PATH=$(DOCKER_CERT_PATH) \
		-e TRITON_ACCOUNT=$(TRITON_ACCOUNT) \
		-e TRITON_DC=$(TRITON_DC) \
		$(SDC_KEYS_VOL) -w /src \
		$(testImage):$(tag) python3 tests.py


## Print environment for build debugging
debug:
	@echo WORKSPACE=$(WORKSPACE)
	@echo GIT_COMMIT=$(GIT_COMMIT)
	@echo GIT_BRANCH=$(GIT_BRANCH)
	@echo namespace=$(namespace)
	@echo tag=$(tag)
	@echo image=$(image)
	@echo testImage=$(testImage)

check_var = $(foreach 1,$1,$(__check_var))
__check_var = $(if $(value $1),,\
	$(error Missing $1 $(if $(value 2),$(strip $2))))
