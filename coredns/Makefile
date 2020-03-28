.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= dns
DOMAIN_NAME    ?= test.dev.superhub.io
NAMESPACE      ?= dns
CHART_VERSION  ?= 1.10.0


kubectl := kubectl --context="$(DOMAIN_NAME)"

deploy: install

install:
	-$(kubectl) create ns $(NAMESPACE)
	$(kubectl) -n $(NAMESPACE) apply -f manifests.yaml

undeploy:
	$(kubectl) -n $(NAMESPACE) delete -f manifests.yaml

-include ../Mk/phonies
