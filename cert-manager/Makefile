.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= cert-manager
DOMAIN_NAME    ?= test.dev.superhub.io
NAMESPACE 	   ?= cert-manager
HELM_CHART     ?= stable/cert-manager
CHART_VERSION  ?= v0.6.6
KUBE_FLAVOR    ?=

export HELM_HOME ?= $(shell pwd)/.helm

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init fetch purge install issuer

init:
	@mkdir -p $(HELM_HOME) charts
	$(helm) init --client-only --upgrade

fetch:
	$(helm) fetch \
		--destination charts \
		--untar $(HELM_CHART) \
		--version $(CHART_VERSION)

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) && \
		$(kubectl) get crd -o name | grep -F certmanager.k8s.io | xargs $(kubectl) delete || exit 0

install:
	-$(kubectl) create namespace $(NAMESPACE)
	$(kubectl) label --overwrite=true namespace $(NAMESPACE) certmanager.k8s.io/disable-validation=true
	$(kubectl) apply -f crds.yaml
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install charts/$(notdir $(HELM_CHART)) \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--wait \
			--values values.yaml \
			--version $(CHART_VERSION)
ifeq ($(KUBE_FLAVOR),openshift)
	$(kubectl) apply -f cert-manager-rbac-patch.yaml
endif

issuer:
	for i in $$(seq 1 24); do \
		if $(kubectl) apply -f prod-cluster-issuer.yaml; then exit 0; fi; \
		sleep 5; \
	done; \
	exit 1
	$(kubectl) apply -f staging-cluster-issuer.yaml
.PHONY: issuer

undeploy: init
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
	-$(kubectl) get crd -o name | grep -F certmanager.k8s.io | xargs $(kubectl) delete

clean:
	rm -rf $(HELM_HOME) charts/$(notdir $(HELM_CHART))

-include ../Mk/phonies
