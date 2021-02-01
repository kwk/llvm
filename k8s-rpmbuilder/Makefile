# When you run make VERBOSE=1, executed commands will be printed before
# executed, verbose flags are turned on and quiet flags are turned off for
# various commands. Use V_FLAG in places where you can toggle on/off verbosity
# using -v. Use Q_FLAG in places where you can toggle on/off quiet mode using
# -q.
Q = @
Q_FLAG = -q
V_FLAG =
S_FLAG = -s
ifeq ($(VERBOSE),1)
       Q =
       S_FLAG = 
       Q_FLAG = 
       V_FLAG = -v
endif

# It's necessary to set this because some environments don't link sh -> bash.
SHELL := /bin/bash

# Change this to your own container image repo (e.g. on quay.io or docker hub)
# NOTE: Tags will be appended to this repo URL using a ":"
CONTAINER_IMAGE_REPO := quay.io/kkleine/llvm-ci

PROJECT_DIR=$(shell pwd)

# For the global "prepare-secrets" target all targets in this variable will be executed
PREPARE_SECRET_TARGETS =

CI_GIT_COMMIT_ID := $(shell git rev-parse --short HEAD)
IS_DIRTY := no
ifneq ($(shell git status --porcelain --untracked-files=no),)
       CI_GIT_COMMIT_ID := $(CI_GIT_COMMIT_ID)-dirty
	   IS_DIRTY := yes
endif

.PHONY: ready-to-deploy
## Will issue an error when the repo is not ready to be deployed
ready-to-deploy:
ifeq ($(IS_DIRTY),yes)
	$(error CAUTION: The repository is dirty, meaning you have uncommitted changes. \
	When you keep changing the same dirty container image and push it to the container image registry, \
	the cluster will not pull it because it thinks it already has it. \
	Commit your changes and then deploy it. This will force the Kubernetes cluster to \
	always grab the fresh copy of your container image.)
endif

ARCH=$(shell arch)

# Find out which container tool to use (currently only podman and docker are supported)
# DOCKER_BIN := $(shell command -v docker 2> /dev/null)
# DOCKER_COMPOSE_BIN := $(shell command -v docker-compose 2> /dev/null)
# PODMAN_BIN := $(shell command -v podman 2> /dev/null)
# PODMAN_COMPOSE_BIN := $(shell command -v podman-compose 2> /dev/null)
# CONTAINER_TOOL := $(shell [[ -z "$(PODMAN_BIN)" ]] && echo $(DOCKER_BIN) || echo $(PODMAN_BIN))
# COMPOSE_TOOL := $(shell [[ -z "$(PODMAN_COMPOSE_BIN)" ]] && echo $(DOCKER_COMPOSE_BIN) || echo $(PODMAN_COMPOSE_BIN))

CONTAINER_TOOL := docker
COMPOSE_TOOL := docker-compose

# This is the default URL:PORT address to the master on your cluster
K8S_NAMESPACE := $(shell kubectl config view --minify --output 'jsonpath={..namespace}')

.PHONY: show-container-tool
## Show which container tool was automatically selected to be used by make: docker (preferred) podman.
## QUICK TIP: To overwrite container tool "make CONTAINER_TOOL=/path/to/docker/or/podman <TARGET>"
show-container-tool:
	@echo $(CONTAINER_TOOL)

.PHONY: show-compose-tool
## Show which container tool was automatically selected to be used by make: docker-compose (preferred) or podman-compose.
## QUICK TIP: To overwrite container tool "make COMPOSE_TOOL=/path/to/docker-compose/or/podman-compose <TARGET>"
show-compose-tool:
	@echo $(COMPOSE_TOOL)

RPMBUILDER_IMAGE := $(CONTAINER_IMAGE_REPO):rpmbuilder-fedora-33-$(ARCH)-$(CI_GIT_COMMIT_ID)

.PHONY: rpmbuilder-image
## Generates a container image to be used for building RPMs.
rpmbuilder-image: Dockerfile
	@echo Building image ${RPMBUILDER_IMAGE}
	$(CONTAINER_TOOL) build $(Q_FLAG) . -f Dockerfile -t ${RPMBUILDER_IMAGE}

.PHONY: push-rpmbuilder-image
## Pushes the rpmbuilder container images to a registry.
push-rpmbuilder-image:
	@echo Pushing image ${RPMBUILDER_IMAGE}
	$(CONTAINER_TOOL) push ${RPMBUILDER_IMAGE}

.PHONY: delete-rpmbuilder-deployment
## Removes all parts of the rpmbuilder deployment from the Kubernetes cluster
delete-rpmbuilder-deployment:
	-kubectl delete pod,secret --grace-period=0 --force -l app=rpmbuilder -l tier=llvm

.PHONY: deploy-rpmbuilder
## Deletes and recreates the rpmbuilder container image as a pod on a Kubernetes cluster.
deploy-rpmbuilder: ready-to-deploy rpmbuilder-image push-rpmbuilder-image delete-rpmbuilder-deployment
	export RPMBUILDER_IMAGE=$(RPMBUILDER_IMAGE) \
	&& envsubst '$${RPMBUILDER_IMAGE}' < ./k8s/pod.yaml > ./pod.out.yaml
	kubectl apply -f ./pod.out.yaml

include ./help.mk

