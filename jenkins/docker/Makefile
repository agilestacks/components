.DEFAULT_GOAL := build

dirname   := $(notdir $(abspath ..))
registry  ?= docker.io
version   ?= $(shell git log -n 1 --pretty='format:%cd' --date=format:'%Y%m%d')-$(shell git rev-parse --short HEAD)
image     ?= $(registry)/agilestacks/$(dirname):$(version)
container ?= jenkins
UC_DISABLED ?= true
# DOCKER_BUILD_OPTS ?= --no-cache --force-rm
DOCKER_RUN_OPTS ?= --env "JENKINS_OPTS=-Djenkins.slaves.JnlpSlaveAgentProtocol3.enabled=true" --env "ADMIN_USER=admin" --env "ADMIN_PASSWORD=secret" --env "SERVICE_ACCOUNT_USER=robot" --env "SERVICE_ACCOUNT_PASSWORD=secret"

build:
	docker build --build-arg="UC_DISABLED=$(UC_DISABLED)" $(BUILD_OPTS) -t $(image) .
.PHONY: build

run:
	docker run --name=$(container) $(DOCKER_RUN_OPTS) --rm -i -t -p 8080:8080 -p 50000:50000 -p 50001:50001 $(image)
.PHONY: run

attach:
	docker exec -i -t $(container) bash
.PHONY: run

push:
	docker push $(image)
.PHONY: push
