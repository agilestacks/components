.DEFAULT_GOAL := deploy

export HELM_HOME ?= $(shell pwd)/.helm

NAMESPACE       ?= cert-manager
COMPONENT_NAME  ?= cert-manager
DOMAIN_NAME     ?= default
kubectl         ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"


namespace:
	- $(kubectl) create namespace $(NAMESPACE)
.PHONY: namespace

init: 
	@ echo "this space intentionally left blank"
.PHONY: init

purge:
	-$(kubectl) delete --namespace=kube-system -f cert-manager-ks.yaml
	-$(kubectl) delete --namespace=cert-manager -f cert-manager-cs.yaml
	-$(kubectl) delete -f cert-manager.yaml
	-$(kubectl) delete -f cert-manager-crds.yaml
.PHONY: purge

install: namespace
	$(kubectl) label --overwrite=true namespace cert-manager certmanager.k8s.io/disable-validation=true
	$(kubectl) apply -f cert-manager-crds.yaml
	$(kubectl) create --namespace=kube-system -f cert-manager-ks.yaml
	$(kubectl) create --namespace=cert-manager -f cert-manager-cs.yaml
.PHONY: install

deploy: init purge install
	$(kubectl)  apply -f prod-cluster-issuer.yaml 
	$(kubectl) --namespace=cert-manager apply -f staging-issuer.yaml
.PHONY: deploy

undeploy: purge
	@ echo "undeploying cert-manager"
.PHONY: undeploy

