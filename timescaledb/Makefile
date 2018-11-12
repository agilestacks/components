.DEFAULT_GOAL := deploy

export HELM_HOME      ?= $(shell pwd)/.helm
export NAMESPACE      ?= timescaledb
export COMPONENT_NAME ?= timescaledb
export DOMAIN_NAME    ?= default

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

CLOUD_KIND ?= aws

deploy: clean init purge install
.PHONY: deploy

init:
	@mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade
	@mkdir -p charts
.PHONY: init

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
.PHONY: purge

install:
	$(kubectl) apply -f namespace.yaml
	$(kubectl) apply -f $(CLOUD_KIND)-storage-class.yaml
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install charts/timescaledb \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--values values.yaml
.PHONY: install

undeploy: init
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
.PHONY: undeploy

clean:
	@rm -rf $(HELM_HOME)
.PHONY: clean