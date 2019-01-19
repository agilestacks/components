.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= cluster-autoscaler
DOMAIN_NAME    ?= dev.dev.superhub.io
NAMESPACE      ?= kube-system

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy:
	$(kubectl) apply -f rbac.yaml
	$(kubectl) apply -f service-account.yaml
	$(kubectl) apply -f pod-distruption-budget.yaml
	$(kubectl) apply -f deployment.yaml

undeploy:
	-$(kubectl) delete -f pod-distruption-budget.yaml
	-$(kubectl) delete -f deployment.yaml
	-$(kubectl) delete -f service-account.yaml
	-$(kubectl) delete -f rbac.yaml

-include ../Mk/phonies
