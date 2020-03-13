.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= coredns
DOMAIN_NAME    ?= test.dev.superhub.io
NAMESPACE      ?= coredns
CHART_VERSION  ?= 1.10.0

export HELM_HOME ?= $(shell pwd)/.helm

kubectl := kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    := helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init fetch purge install

init:
	@mkdir -p $(HELM_HOME) charts
	$(helm) init --client-only --upgrade

fetch:
	$(helm) fetch \
		--destination charts \
		--untar stable/coredns \
		--version $(CHART_VERSION)

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

install:
	- $(kubectl) create ns $(NAMESPACE)
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install charts/coredns \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--values values.yaml

undeploy: init
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

clean:
	rm -rf $(HELM_HOME) charts

-include ../Mk/phonies