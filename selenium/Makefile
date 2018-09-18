.DEFAULT_GOAL := deploy

export HELM_HOME      ?= $(shell pwd)/.helm
export COMPONENT_NAME ?= selenium
export NAMESPACE      ?= selenium
export DOMAIN_NAME    ?= dev.kubernetes.delivery
export kubectl        ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm           ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

HELM_CHART=stable/selenium
VALUES_FILE=values.yaml

deploy: clean init fetch install
.PHONY: deploy

init:
	mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade
	@mkdir -p tmp

fetch:
	$(helm) fetch \
			--destination charts \
			--untar $(HELM_CHART)
.PHONY: fetch

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
.PHONY: install

undeploy: init
	-$(kubectl) delete -f ingress.yaml
	-$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME)
.PHONY: undeploy

clean:
	rm -rf $(HELM_HOME)
	rm -rf charts/$(notdir $(HELM_CHART))
	rm -rf tmp
