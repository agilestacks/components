.DEFAULT_GOAL := build

registry  ?= docker.io
version   ?= $(shell git log -n 1 --pretty='format:%cd' --date=format:'%Y%m%d')-$(shell git rev-parse --short HEAD)
container ?= ceph-disk-cleanup
image     ?= $(registry)/agilestacks/$(container):$(version)

build:
	docker build $(BUILD_OPTS) -t $(image) .
.PHONY: build

run:
	docker run --name=$(container) --rm -it \
		$(image) bash
.PHONY: run

push:
	docker push $(image)
.PHONY: push