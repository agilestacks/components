.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export NAMESPACE    	   ?= kube-system
export COMPONENT_NAME      ?= kubernetes-dashboard
export DOMAIN_NAME         ?= default
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"


deploy:
	$(kubectl) apply --namespace $(NAMESPACE) -f serviceaccount.yaml
	$(kubectl) apply --namespace $(NAMESPACE) -f rbac-view-all.yaml
	$(kubectl) apply --namespace $(NAMESPACE) -f deployment.yaml
	$(kubectl) apply --namespace $(NAMESPACE) -f service.yaml
	$(kubectl) apply --namespace $(NAMESPACE) -f ingress.yaml
.PHONY: deploy

undeploy:
	$(kubectl) delete --namespace $(NAMESPACE) -f ingress.yaml | true
	$(kubectl) delete --namespace $(NAMESPACE) -f service.yaml | true
	$(kubectl) delete --namespace $(NAMESPACE) -f deployment.yaml | true
	$(kubectl) delete --namespace $(NAMESPACE) -f rbac-view-all.yaml | true
	$(kubectl) delete --namespace $(NAMESPACE) -f serviceaccount.yaml | true
.PHONY: undeploy
