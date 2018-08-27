.DEFAULT_GOAL := deploy

export HELM_HOME      ?= $(shell pwd)/.helm
export NAMESPACE      ?= kube-system
export COMPONENT_NAME ?= kubernetes-dashboard
export DOMAIN_NAME    ?= default
export kubectl        ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm           ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy:
	$(kubectl) apply -f serviceaccount.yaml
	$(kubectl) apply -f rbac-view-all.yaml
	$(kubectl) apply -f rbac-minimal.yaml
	$(kubectl) apply -f deployment.yaml
	$(kubectl) apply -f service.yaml
	$(kubectl) apply -f ingress.yaml
.PHONY: deploy

undeploy:
	-$(kubectl) delete -f ingress.yaml
	-$(kubectl) delete -f service.yaml
	-$(kubectl) delete -f deployment.yaml
	-$(kubectl) delete -f rbac-view-all.yaml
	-$(kubectl) delete -f rbac-minimal.yaml
	-$(kubectl) delete -f serviceaccount.yaml
.PHONY: undeploy
