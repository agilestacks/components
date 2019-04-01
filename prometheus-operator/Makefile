.DEFAULT_GOAL := deploy

COMPONENT_NAME   ?= prometheus-operator
HELM_CHART   	 ?= prometheus-operator
DOMAIN_NAME      ?= dev.kubernetes.delivery
NAMESPACE 	     ?= monitoring
CHART_VERSION    ?= 5.0.1
CLOUD_TYPE   	 ?= aws

export HELM_HOME           ?= $(shell pwd)/.helm

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init fetch purge install output

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
	$(MAKE) -C $(CLOUD_TYPE) $@
#	-$(kubectl) create secret generic thanos-objstore-config --from-file=thanos.yaml=thanos-config.yaml
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install charts/$(notdir $(HELM_CHART)) \
			--name $(COMPONENT_NAME) \
			--name-template $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--wait \
			--values values.yaml \
			--version $(CHART_VERSION)

	-$(kubectl) apply -f thanos/thanos-compactor.yaml
	-$(kubectl) apply -f thanos/thanos-querier.yaml
	-$(kubectl) apply -f thanos/thanos-ruler.yaml
	-$(kubectl) apply -f thanos/thanos-store-gateway.yaml
	-$(kubectl) apply -f thanos/service-monitors.yaml

undeploy: init
	-$(kubectl) delete -f thanos/thanos-compactor.yaml
	-$(kubectl) delete -f thanos/thanos-querier.yaml
	-$(kubectl) delete -f thanos/thanos-ruler.yaml
	-$(kubectl) delete -f thanos/thanos-store-gateway.yaml
	-$(kubectl) delete -f thanos/service-monitors.yaml

	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

	-$(kubectl) delete crd/alertmanagers.monitoring.coreos.com
	-$(kubectl) delete crd/prometheuses.monitoring.coreos.com
	-$(kubectl) delete crd/prometheusrules.monitoring.coreos.com
	-$(kubectl) delete crd/servicemonitors.monitoring.coreos.com
	$(MAKE) -C $(CLOUD_TYPE) $@

clean:
	rm -rf $(HELM_HOME) charts/$(notdir $(HELM_CHART))

-include ../Mk/phonies
