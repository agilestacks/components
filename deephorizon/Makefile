.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= deephorizon
DOMAIN_NAME    ?= test.dev.superhub.io
NAMESPACE      ?= deephorizon
KUBE_FLAVOR    ?=
IMAGE_REPO  ?= agilestacks/deephorizon
IMAGE_TAG   ?= latest
IMAGE_NAME  ?= $(IMAGE_REPO):$(IMAGE_TAG)

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy: purge install

purge:
	$(kubectl) delete -f manifests.yaml

install:
	$(kubectl) apply -f manifests.yaml

undeploy:
	$(kubectl) delete -f manifests.yaml

build:
	docker build -t $(IMAGE_NAME) .
.PHONY: build

push:
	docker push $(IMAGE_NAME)
.PHONY: push

test:
	docker run -ti --rm --entrypoint '' $(IMAGE_NAME) bash -c 'cd hooks && lua lib/selftest.lua 2> /dev/null'
.PHONY: test

clean:
	-docker rmi $(IMAGE_NAME)
.PHONY: clean
-include ../Mk/phonies
