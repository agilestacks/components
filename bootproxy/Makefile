.DEFAULT_GOAL := deploy

export COMPONENT_NAME ?= bootproxy
export NAMESPACE      ?= kube-system
REGISTRY              ?= agilestacks
IMAGE                 ?= $(REGISTRY)/$(COMPONENT_NAME)
IMAGE_VERSION         ?= $(shell git rev-parse HEAD | colrm 7)
IMAGE_TAG             ?= latest
REGISTRY_PASS         ?= ~/.docker/agilestacks.txt

kubectl := kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy: purge install

undeploy: purge

install:
	$(kubectl) apply -f manifests.yaml

purge:
	-$(kubectl) delete -f manifests.yaml

.PHONY: login
