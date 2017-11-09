.DEFAULT_GOAL := build

dirname := $(notdir $(abspath .))
image ?= agilestacks/$(dirname)
container ?= fluentd

build:
	docker build --no-cache --force-rm -t $(image) .
.PHONY: build

run:
	docker run --name=$(container) $(image)
.PHONY: run

attach:
	docker exec -i -t $(container) bash
.PHONY: run

push:
	docker push $(image)
.PHONY: push
