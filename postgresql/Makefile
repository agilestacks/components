.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export NAMESPACE    	   ?= postgresql
export COMPONENT_NAME      ?= postgresql
export DOMAIN_NAME         ?= default
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init fetch install output
.PHONY: deploy

init:
	@mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade
	@mkdir -p charts

fetch:
	$(helm) fetch \
		--destination charts \
		--untar stable/postgresql \
		--version 0.8.3
.PHONY: fetch

install:
	$(kubectl) apply -f namespace.yaml
	$(kubectl) apply -f aws-storage-class.yaml
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

output:
	@echo Outputs:
	@echo database_url=$(COMPONENT_NAME)-postgresql.$(NAMESPACE).svc.cluster.local
	@echo
	@echo PostgreSQL has been installed successfully
.PHONY: output
