.DEFAULT_GOAL := deploy

DOMAIN_NAME  ?= dev.kubernetes.delivery
NAMESPACE    ?= metallb-system

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy:
	$(kubectl) apply -f metallb-manifests.yaml

undeploy:
	-$(kubectl) delete -f metallb-manifests.yaml

-include ../Mk/phonies
