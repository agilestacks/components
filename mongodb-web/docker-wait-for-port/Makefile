.DEFAULT_GOAL := deploy

docker ?= docker

REGISTRY  ?= docker.io
VERSION   ?= 0.0.1
IMAGE     ?= $(REGISTRY)/agilestacks/wait-for-port

build:
	$(docker) build . --rm --compress --build-arg VERSION=$(VERSION) -t $(IMAGE):$(VERSION)
.PHONY: build

push:
	docker tag  $(IMAGE):$(VERSION) $(IMAGE):latest
	docker push $(IMAGE):$(VERSION)
	docker push $(IMAGE):latest
.PHONY: push

