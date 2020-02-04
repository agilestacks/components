.DEFAULT_GOAL := deploy

DOMAIN_NAME  ?= dev.test.superhub.io
NAMESPACE    ?= kube-system
HUB_PROVIDES ?=

ifneq (,$(filter tls-ingress,$(HUB_PROVIDES)))
	INGRESS:=ingress-tls
else
	INGRESS:=ingress
endif

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy:
	-$(kubectl) create ns $(NAMESPACE)
	$(kubectl) apply -f templates/serviceaccount.yaml
	$(kubectl) apply -f templates/clusterrolebinding.yaml
	$(kubectl) apply -f templates/deployment.yaml
	$(kubectl) apply -f templates/service.yaml
	$(kubectl) apply -f templates/$(INGRESS).yaml

undeploy:
	-$(kubectl) delete -f templates/$(INGRESS).yaml
	-$(kubectl) delete -f templates/service.yaml
	-$(kubectl) delete -f templates/deployment.yaml

-include ../Mk/phonies

