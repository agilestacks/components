.DEFAULT_GOAL := deploy

export TF_VAR_component          ?= traefik
export TF_VAR_domain_name        ?= test.dev.superhub.io
export TF_VAR_namespace          ?= ingress
export TF_VAR_kubeconfig_context ?= $(TF_VAR_domain_name)

export TF_VAR_azure_resource_group_name ?= superhub-eastus2

CLOUD_KIND          ?= aws
ACM_CERTIFICATE_ARN ?=
CHART_VERSION       ?= 1.68.5
CHART               ?= stable/traefik
HELM_TIMEOUT        ?= 900
HUB_PROVIDES        ?=

# we're taking a hard line here. no HTTP allowed
# We can't be sure if cert-manager will be supplied by the platform
# but it WILL be supplied somewhere
PROTOCOL:=https
TLS_VALUES_FILE:=--values values-tls.yaml --values values-tls.yaml
DASHBOARD_VALUES_FILE:=--values values-dashboard.yaml
PROVIDES:=tls-ingress

export HELM_HOME          ?= $(shell pwd)/.helm

helm        ?= helm --kube-context="$(TF_VAR_kubeconfig_context)" --tiller-namespace="kube-system"

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
	rm -rf $(HELM_HOME) charts $(TF_DATA_DIR)

install:
	if ! $(helm) list -q --namespace $(TF_VAR_namespace) | grep -E '^$(TF_VAR_component)$$'; then \
		$(helm) install charts/$(notdir $(CHART)) \
			--name $(TF_VAR_component) \
			--namespace $(TF_VAR_namespace) \
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
	$(helm) upgrade $(TF_VAR_component) charts/$(notdir $(CHART)) \
		--namespace $(TF_VAR_namespace) \
		--wait \
		--values $(VALUES_FILE) \
		$(TLS_VALUES_FILE) \
		$(DASHBOARD_VALUES_FILE) \
		--version $(CHART_VERSION)

output:
	@echo
	@echo Outputs:
	@echo ingress_protocol = $(PROTOCOL)
	@echo provides = $(PROVIDES)
	@echo

uninstall:
	$(helm) list -q --namespace $(TF_VAR_namespace) | grep -E '^$(TF_VAR_component)$$' && \
		$(helm) delete --purge $(TF_VAR_component)
