.DEFAULT_GOAL := build

DIRNAME := $(notdir $(abspath .))
IMAGE ?= agilestacks/$(DIRNAME)
CONTAINER ?= cerebro
CEREBRO_VERSION ?= 0.8.5
DOCKER_BUILD_OTPS := --no-cache  --force-rm "

deploy: build push

build:
	docker build --build-arg="CEREBRO_VERSION=$(CEREBRO_VERSION)" $(DOCKER_BUILD_OPTS) \
		-t $(IMAGE):$(CEREBRO_VERSION) \
		-t $(IMAGE):latest .
.PHONY: build

run:
	docker run --name=$(CONTAINER) $(IMAGE)
.PHONY: run

attach:
	docker exec -i -t $(CONTAINER) bash
.PHONY: run

push:
	docker tag  $(IMAGE):$(CEREBRO_VERSION) $(IMAGE):latest
	docker push $(IMAGE):$(CEREBRO_VERSION)
	docker push $(IMAGE):latest
.PHONY: push
