# Makefile for building, shipping, and testing the container.

MAKEFLAGS += --warn-undefined-variables
.DEFAULT_GOAL := build
.PHONY: *

# we get these from CI environment if available, otherwise from git
GIT_COMMIT ?= $(shell git rev-parse --short HEAD)
GIT_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)

namespace ?= autopilotpattern
tag := branch-$(shell basename $(GIT_BRANCH))
image := $(namespace)/nginx

## Display this help message
help:
	@awk '/^##.*$$/,/[a-zA-Z_-]+:/' $(MAKEFILE_LIST) | awk '!(NR%2){print $$0p}{p=$$0}' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' | sort

# ------------------------------------------------
# Target environment configuration

#dockerLocal := DOCKER_HOST= DOCKER_TLS_VERIFY= DOCKER_CERT_PATH= docker
dockerLocal := docker
#composeLocal := DOCKER_HOST= DOCKER_TLS_VERIFY= DOCKER_CERT_PATH= docker-compose
composeLocal := docker-compose


# ------------------------------------------------
# Container builds

## Builds the application container image locally
build:
	$(dockerLocal) build -t=$(image):$(tag) .

## Push the current application container images to the Docker Hub
push:
	$(dockerLocal) push $(image):$(tag)

## Tag the current images as 'latest' and push them to the Docker Hub
ship:
	$(dockerLocal) tag $(image):$(tag) $(image):latest
	$(dockerLocal) push $(image):$(tag)
	$(dockerLocal) push $(image):latest


# -------------------------------------------------------
# helper functions for testing if variables are defined

## Print environment for build debugging
debug:
	@echo GIT_COMMIT=$(GIT_COMMIT)
	@echo GIT_BRANCH=$(GIT_BRANCH)
	@echo namespace=$(namespace)
	@echo tag=$(tag)
	@echo image=$(image)

check_var = $(foreach 1,$1,$(__check_var))
__check_var = $(if $(value $1),,\
	$(error Missing $1 $(if $(value 2),$(strip $2))))
