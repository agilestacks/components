.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= etcd
DOMAIN_NAME    ?= test.dev.superhub.io
NAMESPACE      ?= etcd

kubectl ?= kubectl --context="$(DOMAIN_NAME)"

deploy: install

install:
	$(kubectl) create ns $(NAMESPACE)
	$(kubectl) -n $(NAMESPACE) -f manifests.yaml

undeploy:
	$(kubectl) -n $(NAMESPACE) delete -f manifests.yaml

-include ../Mk/phonies
