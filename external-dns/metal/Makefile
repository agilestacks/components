.DEFAULT_GOAL := deploy

export NAMESPACE    ?= kube-system

kubectl := kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy:
	$(kubectl) apply -f ../manifests.yaml
	$(kubectl) apply -f deployment.yaml

undeploy:
	- $(kubectl) delete -f deployment.yaml

-include ../Mk/phonies
