.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export NAMESPACE    	   ?= nginx-ingress
export COMPONENT_NAME      ?= nginxing
export DOMAIN_NAME         ?= default
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
export kind                ?= aws

deploy: clean init fetch install output
	sh ./deploy-$(kind).sh
.PHONY: deploy

init:
	@mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade
	@mkdir -p charts

fetch:
	$(helm) fetch \
		--destination charts \
		--untar stable/nginx-ingress
.PHONY: fetch

install:
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install charts/nginx-ingress \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--wait \
			--values values.yaml
.PHONY: install

undeploy: init
	sh ./undeploy-$(kind).sh
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
.PHONY: undeploy

clean:
	@rm -rf $(HELM_HOME)
	@rm -rf charts

output:
	@echo Outputs:
	@echo ingress_fqdn=$(URL_PREFIX).$(DOMAIN_NAME)
.PHONY: output
