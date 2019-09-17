 .DEFAULT_GOAL := build

registry  ?= docker.io
version   ?= $(shell git log -n 1 --pretty='format:%cd' --date=format:'%Y%m%d')-$(shell git rev-parse --short HEAD)
container ?= gitlab-token-generator
image     ?= $(registry)/agilestacks/$(container):$(version)

build:
	docker build $(BUILD_OPTS) -t $(image) .
.PHONY: build

run:
	docker run --name=$(container) --rm -it \
		-e GITLAB_URL=$(GITLAB_URL) \
		-e GITLAB_ADMIN_USER=$(GITLAB_SERVICEACCOUNT) \
		-e GITLAB_ADMIN_PASSWD=$(GITLAB_SERVICEACCOUNT_PASS) \
		$(image)
.PHONY: run

push:
	docker push $(image)
.PHONY: push