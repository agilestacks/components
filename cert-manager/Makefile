.DEFAULT_GOAL := deploy

export HELM_HOME ?= $(shell pwd)/.helm

NAMESPACE       ?= cert-manager
COMPONENT_NAME  ?= cert-manager
DOMAIN_NAME     ?= default
kubectl         ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm            ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
CHART           ?= charts/cert-manager
CHART_VERSION   ?= v0.5.2

$(HELM_HOME):
	mkdir -p "$@"

charts:
	mkdir -p "$@"

namespace:
	- $(kubectl) create namespace $(NAMESPACE)
.PHONY: namespace

init: $(HELM_HOME) charts
	@ $(helm) init --client-only --upgrade --wait
.PHONY: init

fetch:
	$(helm) fetch \
		--destination charts \
		--untar stable/cert-manager \
		--version $(CHART_VERSION)
.PHONY: fetch

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
.PHONY: purge

install: namespace
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install $(CHART) \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--version $(CHART_VERSION) \
			--replace \
			--values values.yaml \
			--wait
.PHONY: install

deploy: clean init fetch purge install
	$(kubectl) apply -f prod-issuer.yaml
	$(kubectl) apply -f staging-issuer.yaml
.PHONY: deploy

undeploy: init
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
.PHONY: undeploy

clean:
	@ rm -rf $(HELM_HOME)
	@ rm -rf charts
.PHONY: clean
