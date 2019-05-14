.DEFAULT_GOAL := deploy

DOMAIN_NAME  ?= dev.kubernetes.delivery
NAMESPACE    ?= kube-system


kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy:
	$(kubectl) apply -f portworx-pvc-controller.yaml
	$(kubectl) apply -f portworx-internal-kvdb.yaml
	$(kubectl) apply -f ingress.yaml

undeploy:
	-$(kubectl) delete -f portworx-internal-kvdb.yaml
	-$(kubectl) delete -f portworx-pvc-controller.yaml
	-$(kubectl) delete -f ingress.yaml

-include ../Mk/phonies
