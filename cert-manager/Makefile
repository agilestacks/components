.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= cert-manager
DOMAIN_NAME    ?= test.dev.superhub.io
NAMESPACE 	   ?= cert-manager
HELM_CHART     ?= jetstack/cert-manager
CHART_VERSION  ?= v0.8.0
KUBE_FLAVOR    ?=

export HELM_HOME ?= $(shell pwd)/.helm

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

ADDITIONAL_VALUES :=
ifeq ($(KUBE_FLAVOR),openshift)
deploy: clean init fetch purge install openshift issuer
ADDITIONAL_VALUES := --values values-openshift.yaml
else
deploy: clean init fetch purge install issuer
endif

init:
	@mkdir -p $(HELM_HOME) charts
	$(helm) init --client-only --upgrade

# https://github.com/jetstack/cert-manager/pull/1694
fetch:
	$(helm) repo add jetstack https://charts.jetstack.io
	$(helm) fetch \
		--destination charts \
		--untar $(HELM_CHART) \
		--version $(CHART_VERSION)
	patch -i validating-webhook.yaml.diff charts/cert-manager/charts/webhook/templates/validating-webhook.yaml

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) && \
		$(kubectl) get crd -o name | grep -F certmanager.k8s.io | xargs $(kubectl) delete || exit 0

install:
	$(kubectl) apply -f namespace.yaml
	$(kubectl) apply -f crds.yaml
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install charts/$(notdir $(HELM_CHART)) \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--wait \
			--values values.yaml \
			$(ADDITIONAL_VALUES) \
			--version $(CHART_VERSION)

# TODO do we still need this?
# https://github.com/jetstack/cert-manager/blob/master/deploy/charts/cert-manager/templates/deployment.yaml
openshift:
	$(kubectl) apply -f cert-manager-openshift-rbac-patch.yaml
.PHONY: openshift

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
