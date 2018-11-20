.DEFAULT_GOAL := deploy

DOMAIN_NAME ?= dev.kubernetes.delivery
NAMESPACE   ?= kube-system

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy:
	$(kubectl) apply -f serviceaccount.yaml
	$(kubectl) apply -f rbac-view-all.yaml
	$(kubectl) apply -f rbac-minimal.yaml
	$(kubectl) apply -f deployment.yaml
	$(kubectl) apply -f service.yaml
	$(kubectl) apply -f ingress.yaml

undeploy:
	-$(kubectl) delete -f ingress.yaml
	-$(kubectl) delete -f service.yaml
	-$(kubectl) delete -f deployment.yaml
	-$(kubectl) delete -f rbac-view-all.yaml
	-$(kubectl) delete -f rbac-minimal.yaml
	-$(kubectl) delete -f serviceaccount.yaml

include ../Mk/phonies
