.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export NAMESPACE    	   ?= ingress
export COMPONENT_NAME      ?= traefik
export DOMAIN_NAME         ?= default
export CLOUD_KIND          ?= aws
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init fetch install output
	bash -e ./deploy-$(CLOUD_KIND).sh
.PHONY: deploy

init:
	@mkdir -p $(HELM_HOME)
	$(helm) init --client-only --upgrade
	@mkdir -p charts

fetch:
	$(helm) fetch \
		--destination charts \
		--untar stable/traefik
.PHONY: fetch

install:
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install charts/traefik \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--wait \
			--values values.yaml
.PHONY: install

undeploy: init
	bash -e ./undeploy-$(CLOUD_KIND).sh
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
.PHONY: undeploy

clean:
	@rm -rf $(HELM_HOME)
	@rm -rf charts

output:
	@echo Outputs:
	@echo ingress_fqdn=$(URL_PREFIX).$(DOMAIN_NAME)
	@echo sso_ingress_fqdn=$(SSO_URL_PREFIX).$(DOMAIN_NAME)
	@echo
.PHONY: output
