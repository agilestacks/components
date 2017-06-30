.DEFAULT_GOAL := build

dirname   := $(notdir $(abspath .))
registry  ?= docker.io
version   ?= 2.46.1-3
image     ?= $(registry)/agilestacks/$(dirname):$(version)
container ?= jenkins

build:
	docker build --no-cache --force-rm -t $(image) .
.PHONY: build

run:
	docker run --name=$(container) --env "JENKINS_OPTS=-Djenkins.slaves.JnlpSlaveAgentProtocol3.enabled=true" --rm -i -t -p 8080:8080 -p 50000:50000 -p 50001:50001 $(image)
.PHONY: run

attach:
	docker exec -i -t $(container) bash
.PHONY: run

push:
	docker push $(image)
.PHONY: push
