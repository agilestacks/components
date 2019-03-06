.DEFAULT_GOAL := build

REGISTRY  ?= docker.io
VERSION   ?= 2.10.0
IMAGE     ?= $(REGISTRY)/agilestacks/allure
CONTAINER ?= allure


build:
	docker build --build-arg="ALLURE_VERSION=$(VERSION)" --no-cache --force-rm -t $(IMAGE):$(VERSION) .
.PHONY: build

run:
	docker run --name=$(CONTAINER) --entrypoint=sh --rm -it $(IMAGE):$(VERSION)
.PHONY: run

# attach:
# 	docker exec -i -t $(CONTAINER) bash
# .PHONY: run

push:
	docker tag  $(IMAGE):$(VERSION) $(IMAGE):latest
	docker push $(IMAGE):$(VERSION)
	docker push $(IMAGE):latest
.PHONY: push
