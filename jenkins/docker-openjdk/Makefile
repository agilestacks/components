.DEFAULT_GOAL := build

REGISTRY   := docker.io
VERSION    := 8-jdk-slim
IMAGE      := agilestacks/openjdk
CONTAINER  := java
BUILD_OPTS := --no-cache --force-rm

build:
	docker build $(BUILD_OPTS) -t $(IMAGE):$(VERSION) -t $(IMAGE):latest .
.PHONY: build

run:
	docker run --name=$(CONTAINER) --entrypoint=bash --rm -it $(IMAGE):$(VERSION)
.PHONY: run

push:
	docker push $(IMAGE):$(VERSION) 
	docker push $(IMAGE):latest	
.PHONY: push
