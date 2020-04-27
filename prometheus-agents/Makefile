.DEFAULT_GOAL := deploy

DOMAIN_NAME   ?= dev.superhub.io
NAMESPACE			?= monitoring
kubectl       ?= kubectl --context="$(DOMAIN_NAME)"

deploy:
	-$(kubectl) create ns $(NAMESPACE)
	$(kubectl) apply -f service-account.yaml
	$(kubectl) apply -f kube-state-metrics.yaml
	$(kubectl) apply -f node-exporter.yaml

undeploy:
	-$(kubectl) delete -f node-exporter.yaml
	$(kubectl) delete -f kube-state-metrics.yaml
	$(kubectl) delete -f service-account.yaml
