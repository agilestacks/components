.DEFAULT_GOAL := deploy

COMPONENT_NAME   ?= prometheus-operator
HELM_CHART       ?= prometheus-community/kube-prometheus-stack
DOMAIN_NAME      ?= test.dev.superhub.io
NAMESPACE        ?= monitoring
CHART_VERSION    ?= 12.0.1
OPERATOR_VERSION ?= v0.43.2
CLOUD_KIND       ?= aws

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

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
	@mkdir -p charts

fetch:
	$(helm) repo add prometheus-community https://prometheus-community.github.io/helm-charts
	$(helm) repo add stable https://charts.helm.sh/stable
	$(helm) repo update
	$(helm) fetch \
		--destination charts \
		--untar $(HELM_CHART) \
		--version $(CHART_VERSION)

patch:
	sed -i~ -e 's|metrics_path="/metrics/cadvisor", ||' charts/kube-prometheus-stack/templates/prometheus/rules-1.14/k8s.rules.yaml
	sed -i~ -E -e 's/(appVersion: ).*/\1$(OPERATOR_VERSION)/' charts/kube-prometheus-stack/Chart.yaml

purge:
	$(helm) list --uninstalled --failed -q | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) uninstall $(COMPONENT_NAME) && \
		$(kubectl) delete crd/alertmanagerconfigs.monitoring.coreos.com && \
		$(kubectl) delete crd/alertmanagers.monitoring.coreos.com && \
		$(kubectl) delete crd/prometheuses.monitoring.coreos.com && \
		$(kubectl) delete crd/prometheusrules.monitoring.coreos.com && \
		$(kubectl) delete crd/servicemonitors.monitoring.coreos.com && \
		$(kubectl) delete crd/podmonitors.monitoring.coreos.com && \
		$(kubectl) delete crd/thanosrulers.monitoring.coreos.com || exit 0

install:
	-$(kubectl) create namespace $(NAMESPACE)
	$(kubectl) apply -f oidc.yaml
	$(helm) upgrade $(COMPONENT_NAME) charts/$(notdir $(HELM_CHART)) \
		--install --create-namespace \
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

	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) uninstall $(COMPONENT_NAME) || exit 0

	-$(kubectl) delete crd/alertmanagerconfigs.monitoring.coreos.com
	-$(kubectl) delete crd/alertmanagers.monitoring.coreos.com
	-$(kubectl) delete crd/prometheuses.monitoring.coreos.com
	-$(kubectl) delete crd/prometheusrules.monitoring.coreos.com
	-$(kubectl) delete crd/servicemonitors.monitoring.coreos.com
	-$(kubectl) delete crd/podmonitors.monitoring.coreos.com
	-$(kubectl) delete crd/thanosrulers.monitoring.coreos.com

clean:
	rm -rf charts/$(notdir $(HELM_CHART))

-include ../Mk/phonies
