.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm

NAMESPACE      ?= mongodb
COMPONENT_NAME ?= mongodb
DOMAIN_NAME    ?= default
kubectl        ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm           ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
CHART 		   ?= charts/mongodb
CHART_VERSION  ?= 0.4.27

deploy: clean init fetch install
.PHONY: deploy

init:
	@mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade --wait
	@mkdir -p charts

fetch:
	$(helm) fetch \
		--destination charts \
		--untar stable/mongodb \
		--version $(CHART_VERSION)
.PHONY: fetch

install:
	-$(kubectl) create namespace $(mongodb)
	$(kubectl) apply -f aws-storage-class.yaml
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
	-$(kubectl) delete -f aws-storage-class.yaml
.PHONY: undeploy

clean:
	@rm -rf $(HELM_HOME)
	@rm -rf charts
