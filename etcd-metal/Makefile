.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= etcd-metal
DOMAIN_NAME    ?= test.dev.superhub.io
NAMESPACE      ?= dns

kubectl ?= kubectl --context="$(DOMAIN_NAME)"

deploy: install

install:
	-$(kubectl) create ns $(NAMESPACE)
	$(kubectl) -n $(NAMESPACE) apply -f manifests.yaml

undeploy:
	$(kubectl) -n $(NAMESPACE) delete -f manifests.yaml

-include ../Mk/phonies
