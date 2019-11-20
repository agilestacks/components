.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= aws-spot-termination-handler
DOMAIN_NAME    ?= dev.kubernetes.delivery
NAMESPACE      ?= aws-spot-termination-handler


kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy: install

install:
	- $(kubectl) create ns $(NAMESPACE)
	- $(kubectl) apply -k base/

undeploy: init
	- $(kubectl) delete -k base/

-include ../Mk/phonies