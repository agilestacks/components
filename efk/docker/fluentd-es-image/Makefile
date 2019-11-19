.DEFAULT_GOAL := build

DIRNAME := $(notdir $(abspath .))
IMAGE ?= agilestacks/fluentd-elasticsearch
CONTAINER ?= fluentd-elasticsearch
FLUENTD_VERSION ?= v1.6.3
DOCKER_BUILD_OTPS := --no-cache  --force-rm "

deploy: build push

build:
	docker build $(DOCKER_BUILD_OPTS) \
		-t $(IMAGE):$(FLUENTD_VERSION) \
		-t $(IMAGE):latest .
.PHONY: build

run:
	docker run --name=$(CONTAINER) $(IMAGE)
.PHONY: run

attach:
	docker exec -i -t $(CONTAINER) bash
.PHONY: run

push:
	docker tag  $(IMAGE):$(FLUENTD_VERSION) $(IMAGE):latest
	docker push $(IMAGE):$(FLUENTD_VERSION)
	docker push $(IMAGE):latest
.PHONY: push
