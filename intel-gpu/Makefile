.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= intel-gpu
DOMAIN_NAME    ?= dev.kubernetes.delivery
NAMESPACE      ?= kube-system

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy: purge install

purge:
	-$(kubectl) delete -f intel-gpu-manifests.yaml

install:
	$(kubectl) apply -f intel-gpu-manifests.yaml

undeploy: purge

-include ../Mk/phonies
