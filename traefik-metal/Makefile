.DEFAULT_GOAL := deploy

export COMPONENT          ?= traefik-metal
export DOMAIN_NAME        ?= test.dev.superhub.io
export NAMESPACE          ?= ingress
export KUBECONFIG_CONTEXT ?= $(DOMAIN_NAME)

CLOUD_KIND          ?= metal
CHART_VERSION       ?= 1.68.5
CHART               ?= stable/traefik
HELM_TIMEOUT        ?= 900
HUB_PROVIDES        ?=

# we're taking a hard line here. no HTTP allowed
# We can't be sure if cert-manager will be supplied by the platform
# but it WILL be supplied somewhere
PROTOCOL:=https
TLS_VALUES_FILE:=--values values-tls.yaml
DASHBOARD_VALUES_FILE:=--values values-dashboard.yaml
PROVIDES:=tls-ingress

export HELM_HOME          ?= $(shell pwd)/.helm

helm        ?= helm --kube-context="$(KUBECONFIG_CONTEXT)" --tiller-namespace="kube-system"

VALUES_FILE:=values.yaml


deploy: clean init fetch install output
undeploy: uninstall

init:
	@mkdir -p $(HELM_HOME) charts
	$(helm) init --client-only --upgrade --wait

fetch:
	$(helm) fetch \
		--destination charts \
		--untar $(CHART) \
		--version $(CHART_VERSION)

clean:
	rm -rf $(HELM_HOME) charts

install:
	if ! $(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT)$$'; then \
		$(helm) install charts/$(notdir $(CHART)) \
			--name $(COMPONENT) \
			--namespace $(NAMESPACE) \
			--replace \
			--wait \
			--timeout $(HELM_TIMEOUT) \
			--values $(VALUES_FILE) \
			$(TLS_VALUES_FILE) \
			$(DASHBOARD_VALUES_FILE) \
			--version $(CHART_VERSION); \
	else \
		$(MAKE) upgrade; \
	fi
upgrade:
	$(helm) upgrade $(COMPONENT) charts/$(notdir $(CHART)) \
		--namespace $(NAMESPACE) \
		--wait \
		--values $(VALUES_FILE) \
		$(TLS_VALUES_FILE) \
		$(DASHBOARD_VALUES_FILE) \
		--version $(CHART_VERSION)

output:
	$(eval LOAD_BALANCER = $(shell kubectl -n ingress get svc $(COMPONENT) -o json | jq -r .status.loadBalancer.ingress[0].ip))
	@echo
	@echo Outputs:
	@echo ingress_protocol = $(PROTOCOL)
	@echo provides = $(PROVIDES)
	@echo url_prefix = $(URL_PREFIX).$(DOMAIN_NAME)
	@echo sso_url_prefix = $(SSO_URL_PREFIX).$(DOMAIN_NAME)
	@echo load_balancer_dns_record_type = A
	@echo ingress_load_balancer = $(LOAD_BALANCER)
	@echo

uninstall:
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT)$$' && \
		$(helm) delete --purge $(COMPONENT)
