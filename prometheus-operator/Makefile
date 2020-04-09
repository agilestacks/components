.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= prometheus-operator
HELM_CHART     ?= prometheus-operator
DOMAIN_NAME    ?= test.dev.superhub.io
NAMESPACE      ?= monitoring
CHART_VERSION  ?= 8.12.12
OPER_VERSION   ?= v0.38.0
CLOUD_KIND     ?= aws

export HELM_HOME ?= $(shell pwd)/.helm

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init fetch patch purge install
ifeq ($(THANOS_ENABLED),true)
deploy: thanos
undeploy: init unthanos uninstall
THANOS_VALUES := --values values-thanos.yaml
else
undeploy: init uninstall
endif

ifeq ($(CLOUD_KIND),azure)
AZURE_VALUES := --values azure/values.yaml
endif

init:
	@mkdir -p $(HELM_HOME) charts
	$(helm) init --client-only --upgrade

fetch:
	$(helm) fetch \
		--destination charts \
		--untar $(HELM_CHART) \
		--version $(CHART_VERSION)

patch:
	sed -i~ -e 's|metrics_path="/metrics/cadvisor", ||' charts/prometheus-operator/templates/prometheus/rules-1.14/k8s.rules.yaml
	sed -i~ -E -e 's/(appVersion: ).*/\1$(OPER_VERSION)/' charts/prometheus-operator/Chart.yaml

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete $(COMPONENT_NAME) --purge && \
		$(kubectl) delete crd/alertmanagers.monitoring.coreos.com && \
		$(kubectl) delete crd/prometheuses.monitoring.coreos.com && \
		$(kubectl) delete crd/prometheusrules.monitoring.coreos.com && \
		$(kubectl) delete crd/servicemonitors.monitoring.coreos.com && \
		$(kubectl) delete crd/podmonitors.monitoring.coreos.com && \
		$(kubectl) delete crd/thanosrulers.monitoring.coreos.com || exit 0

install:
	-$(kubectl) create namespace $(NAMESPACE)
	-$(kubectl) create -f oidc-crd.yaml
	if ! $(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$'; then \
		$(helm) install charts/$(notdir $(HELM_CHART)) \
			--name $(COMPONENT_NAME) \
			--name-template $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--wait \
			--values values.yaml \
			$(THANOS_VALUES) \
			$(AZURE_VALUES) \
			--version $(CHART_VERSION); \
	else \
		$(MAKE) upgrade; \
	fi

upgrade:
	$(helm) upgrade $(COMPONENT_NAME) charts/$(notdir $(HELM_CHART)) \
		--namespace $(NAMESPACE) \
		--wait \
		--values values.yaml \
		$(THANOS_VALUES) \
		$(AZURE_VALUES) \
		--version $(CHART_VERSION)

thanos:
	-$(kubectl) create secret generic thanos-objstore-config --from-file=$(CLOUD_KIND)/thanos-config.yaml
	$(kubectl) apply -f thanos/thanos-compactor.yaml
	$(kubectl) apply -f thanos/thanos-querier.yaml
	$(kubectl) apply -f thanos/thanos-ruler.yaml
	$(kubectl) apply -f thanos/thanos-store-gateway.yaml
	$(kubectl) apply -f thanos/service-monitors.yaml

unthanos:
	-$(kubectl) delete -f thanos/thanos-compactor.yaml
	-$(kubectl) delete -f thanos/thanos-querier.yaml
	-$(kubectl) delete -f thanos/thanos-ruler.yaml
	-$(kubectl) delete -f thanos/thanos-store-gateway.yaml
	-$(kubectl) delete -f thanos/service-monitors.yaml
	-$(kubectl) delete secret thanos-objstore-config

.PHONY: thanos unthanos

uninstall:
	-$(kubectl) delete -f oidc-crd.yaml

	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

	-$(kubectl) delete crd/alertmanagers.monitoring.coreos.com
	-$(kubectl) delete crd/prometheuses.monitoring.coreos.com
	-$(kubectl) delete crd/prometheusrules.monitoring.coreos.com
	-$(kubectl) delete crd/servicemonitors.monitoring.coreos.com
	-$(kubectl) delete crd/podmonitors.monitoring.coreos.com
	-$(kubectl) delete crd/thanosrulers.monitoring.coreos.com

clean:
	rm -rf $(HELM_HOME) charts/$(notdir $(HELM_CHART))

-include ../Mk/phonies
