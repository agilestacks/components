.DEFAULT_GOAL := deploy

export HELM_HOME		   ?= $(shell pwd)/.helm

NAMESPACE		?= argoproj
COMPONENT_NAME	?= nats
DOMAIN_NAME		?= default
kubectl			?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm			?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
CHART			?= charts/nats
CHART_VERSION	?= 0.0.6
TIMEOUT			?= 300


deploy: clean init fetch install
.PHONY: deploy

init:
	@mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade --wait
	@mkdir -p charts

fetch:
	$(helm) fetch \
		--destination charts \
		--untar stable/nats \
		--version $(CHART_VERSION)
.PHONY: fetch

install:
	-$(kubectl) create namespace $(NAMESPACE)
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install $(CHART) \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--version $(CHART_VERSION) \
			--replace \
			--values values.yaml \
			--wait
.PHONY: install

undeploy: init
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
.PHONY: undeploy

clean:
	@rm -rf $(HELM_HOME)
	@rm -rf charts
