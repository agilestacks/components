.DEFAULT_GOAL := deploy

export HELM_HOME      ?= $(shell pwd)/.helm
export NAMESPACE      ?= postgresql
export COMPONENT_NAME ?= postgresql
export DOMAIN_NAME    ?= default

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

CLOUD_KIND ?= aws

deploy: clean init fetch install
.PHONY: deploy

init:
	@mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade
	@mkdir -p charts
.PHONY: init

fetch:
	$(helm) fetch \
		--destination charts \
		--untar stable/postgresql \
		--version 0.8.3
.PHONY: fetch

install:
	$(kubectl) apply -f namespace.yaml
	$(kubectl) apply -f $(CLOUD_KIND)-storage-class.yaml
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install charts/postgresql \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--values values.yaml
.PHONY: install

undeploy: init
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
	-$(kubectl) delete -f aws-storage-class.yaml
.PHONY: undeploy

clean:
	@rm -rf $(HELM_HOME)
	@rm -rf charts
.PHONY: clean
