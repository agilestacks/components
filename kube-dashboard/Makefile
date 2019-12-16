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
	$(kubectl) apply -f serviceaccount.yaml
	$(kubectl) apply -f rbac-$(RBAC_KIND).yaml
	$(kubectl) apply -f deployment.yaml
	$(kubectl) apply -f service.yaml
	$(kubectl) apply -f $(INGRESS).yaml

undeploy:
	-$(kubectl) delete -f $(INGRESS).yaml
	-$(kubectl) delete -f service.yaml
	-$(kubectl) delete -f deployment.yaml
	-$(kubectl) delete -f rbac-$(RBAC_KIND).yaml
	-$(kubectl) delete -f serviceaccount.yaml

-include ../Mk/phonies
