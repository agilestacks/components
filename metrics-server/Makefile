.DEFAULT_GOAL := deploy

DOMAIN_NAME ?= dev01.dev.superhub.io
NAMESPACE   ?= kube-system

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy:
	$(kubectl) apply -f aggregated-metrics-reader.yaml
	$(kubectl) apply -f auth-delegator.yaml
	$(kubectl) apply -f auth-reader.yaml
	$(kubectl) apply -f metrics-apiservice.yaml
	$(kubectl) apply -f metrics-server-deployment.yaml
	$(kubectl) apply -f metrics-server-service.yaml
	$(kubectl) apply -f resource-reader.yaml

undeploy:
	-$(kubectl) delete -f resource-reader.yaml
	-$(kubectl) delete -f metrics-server-service.yaml
	-$(kubectl) delete -f metrics-server-deployment.yaml
	-$(kubectl) delete -f metrics-apiservice.yaml
	-$(kubectl) delete -f aggregated-metrics-reader.yaml
	-$(kubectl) delete -f auth-delegator.yaml
	-$(kubectl) delete -f auth-reader.yaml

-include ../Mk/phonies
