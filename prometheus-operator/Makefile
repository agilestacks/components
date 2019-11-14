.DEFAULT_GOAL := deploy

COMPONENT_NAME   ?= prometheus-operator
HELM_CHART   	 ?= prometheus-operator
DOMAIN_NAME      ?= dev.kubernetes.delivery
NAMESPACE 	     ?= monitoring
CHART_VERSION    ?= 5.0.1
CLOUD_KIND     ?= aws

export HELM_HOME           ?= $(shell pwd)/.helm

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

ifeq ($(THANOS_ENABLED),true)
deploy: clean init fetch purge thanos-cloud install thanos
undeploy: init unthanos uninstall thanos-uncloud
THANOS_VALUES := --values values-thanos.yaml
else
deploy: clean init fetch purge install
undeploy: init uninstall
endif
ifeq ($(THANOS_ENABLED),true)
endif


init:
	@mkdir -p $(HELM_HOME) charts
	$(helm) init --client-only --upgrade

fetch:
	$(helm) fetch \
		--destination charts \
		--untar $(HELM_CHART) \
		--version $(CHART_VERSION)

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

install:
	-$(kubectl) create namespace $(NAMESPACE)
#	-$(kubectl) create secret generic thanos-objstore-config --from-file=thanos.yaml=thanos-config.yaml
	-$(kubectl) create -f oidc-crd.yaml
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install charts/$(notdir $(HELM_CHART)) \
			--name $(COMPONENT_NAME) \
			--name-template $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--wait \
			--values values.yaml \
			$(THANOS_VALUES) \
			--version $(CHART_VERSION)

thanos-cloud:
	$(MAKE) -C $(CLOUD_KIND) deploy

thanos-uncloud:
	$(MAKE) -C $(CLOUD_KIND) undeploy

thanos:
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

.PHONY: thanos unthanos thanos-cloud thanos-uncloud

uninstall:
	-$(kubectl) delete -f oidc-crd.yaml

	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

	-$(kubectl) delete crd/alertmanagers.monitoring.coreos.com
	-$(kubectl) delete crd/prometheuses.monitoring.coreos.com
	-$(kubectl) delete crd/prometheusrules.monitoring.coreos.com
	-$(kubectl) delete crd/servicemonitors.monitoring.coreos.com
	-$(kubectl) delete crd/podmonitors.monitoring.coreos.com

clean:
	rm -rf $(HELM_HOME) charts/$(notdir $(HELM_CHART))

-include ../Mk/phonies
