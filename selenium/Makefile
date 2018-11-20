.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= selenium
DOMAIN_NAME    ?= dev.kubernetes.delivery
NAMESPACE      ?= selenium

export HELM_HOME ?= $(shell pwd)/.helm

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

HELM_CHART=stable/selenium
VALUES_FILE=values.yaml

deploy: clean init fetch purge install

init:
	@mkdir -p $(HELM_HOME) charts
	$(helm) init --client-only --upgrade
.PHONY: init

fetch:
	$(helm) fetch \
		--destination charts \
		--untar $(HELM_CHART)

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

install:
	$(kubectl) apply -f namespace.yaml
	$(kubectl) apply -f ingress.yaml
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install charts/$(notdir $(HELM_CHART)) \
			--name $(COMPONENT_NAME) \
			--name-template $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--wait \
			--values $(VALUES_FILE)

undeploy: init
	-$(kubectl) delete -f ingress.yaml
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

clean:
	rm -rf $(HELM_HOME) charts/$(notdir $(HELM_CHART))

-include ../Mk/phonies
