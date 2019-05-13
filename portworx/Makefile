.DEFAULT_GOAL := deploy

DOMAIN_NAME  ?= dev.kubernetes.delivery
NAMESPACE    ?= kube-system
HUB_PROVIDES ?=

ifneq (,$(filter tls-ingress,$(HUB_PROVIDES)))
	INGRESS:=ingress-tls
else
	INGRESS:=ingress
endif

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy:
	$(kubectl) apply -f portworx-pvc-controller.yaml
	$(kubectl) apply -f portworx-internal-kvdb.yaml
	$(kubectl) apply -f $(INGRESS).yaml

undeploy:
	-$(kubectl) delete -f portworx-internal-kvdb.yaml
	-$(kubectl) delete -f portworx-pvc-controller.yaml
	-$(kubectl) delete -f $(INGRESS).yaml

-include ../Mk/phonies
