.DEFAULT_GOAL := deploy

DOMAIN_NAME  ?= dev.kubernetes.delivery
NAMESPACE    ?= default

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy:
	$(kubectl) apply -f external-dns-manifests.yaml

undeploy:
	-$(kubectl) delete -f external-dns-manifests.yaml

-include ../Mk/phonies
