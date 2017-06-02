# Makefile for shipping and testing the container image.

MAKEFLAGS += --warn-undefined-variables
.DEFAULT_GOAL := build
.PHONY: *

# we get these from CI environment if available, otherwise from git
GIT_COMMIT ?= $(shell git rev-parse --short HEAD)
GIT_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)
WORKSPACE ?= $(shell pwd)

namespace ?= autopilotpattern
tag := branch-$(shell basename $(GIT_BRANCH))
image := $(namespace)/nginx
example := $(namespace)/nginx-example
backend := $(namespace)/nginx-backend
testImage := $(namespace)/nginx-testrunner

## Display this help message
help:
	@awk '/^##.*$$/,/[a-zA-Z_-]+:/' $(MAKEFILE_LIST) | awk '!(NR%2){print $$0p}{p=$$0}' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' | sort


# ------------------------------------------------
# Container builds

## Builds the application container image
build:
	docker build -t=$(image):$(tag) .

## Builds the application example images
build/examples: build
	sed 's/latest/$(tag)/' examples/Dockerfile > examples/Examplefile
	cd ./examples && docker build -f Examplefile -t=$(example):$(tag) .
	cd ./examples/backend && docker build -t=$(backend):$(tag) .

## Build the test running container
build/tester:
	docker build -f test/Dockerfile -t=$(testImage):$(tag) .

## Push the current application container images to the Docker Hub
push:
	docker push $(image):$(tag)

## Push the current example application container images to the Docker Hub
push/examples:
	docker push $(example):$(tag)
	docker push $(backend):$(tag)
	docker push $(testImage):$(tag)

## Tag the current images as 'latest' and push them to the Docker Hub
ship:
	docker tag $(image):$(tag) $(image):latest
	docker tag $(image):$(tag) $(image):latest
	docker push $(image):$(tag)
	docker push $(image):latest



# ------------------------------------------------
# Test running

## Pull the container images from the Docker Hub
pull:
	docker pull $(image):$(tag)

## Pull the test target images from the docker Hub
pull/examples:
	docker pull $(example):$(tag)
	docker pull $(backend):$(tag)

## Run the example via Docker Compose against the local Docker environment
run/compose:
	cd ./examples/compose && TAG=$(tag) docker-compose up -d

## Run the example via triton-compose on Joyent's Triton
run/triton:
	cd ./examples/triton && TAG=$(tag) triton-compose up -d

## Run the integration test runner. Runs locally but targets Triton.
test:
	$(call check_var, TRITON_PROFILE, \
		required to run integration tests on Triton.)
	docker run --rm \
		-e TAG=$(tag) \
		-e TRITON_PROFILE=$(TRITON_PROFILE) \
		-v ~/.ssh:/root/.ssh:ro \
		-v ~/.triton/profiles.d:/root/.triton/profiles.d:ro \
		-w /src \
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
