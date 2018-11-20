.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= prometheus
DOMAIN_NAME    ?= dev.kubernetes.delivery
NAMESPACE      ?= prometheus

export HELM_HOME ?= $(shell pwd)/.helm

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init namespace purge install_operator install_kube_prom

init:
	@mkdir -p $(HELM_HOME)
	$(helm) init --client-only --upgrade

namespace:
	-$(kubectl) create namespace $(NAMESPACE)

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)-kube-prom$$' && \
		$(helm) delete --purge $(COMPONENT_NAME)-kube-prom || exit 0
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)-operator$$' && \
		$(helm) delete --purge $(COMPONENT_NAME)-operator || exit 0

install_operator:
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)-operator$$' || \
		$(helm) install charts/prometheus-operator \
			--name $(COMPONENT_NAME)-operator \
			--namespace $(NAMESPACE) \
			--replace \
			--wait \
			--values values-operator.yaml
.PHONY: install_operator

install_kube_prom:
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)-kube-prom$$' || \
		$(helm) install charts/kube-prometheus \
			--name $(COMPONENT_NAME)-kube-prom \
			--namespace $(NAMESPACE) \
			--replace \
			--wait \
			--values values-kube-prometheus.yaml
.PHONY: install_kube_prom

undeploy: init clean
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)-kube-prom$$' && \
		$(helm) delete --purge $(COMPONENT_NAME)-kube-prom || exit 0
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)-operator$$' && \
		$(helm) delete --purge $(COMPONENT_NAME)-operator || exit 0

	$(kubectl) get --namespace $(NAMESPACE) svc/$(COMPONENT_NAME)-operated -o=yaml|$(kubectl) delete -f - || true
	$(kubectl) get --namespace $(NAMESPACE) svc/alertmanager-operated -o=yaml|$(kubectl) delete -f - || true
	$(kubectl) get --namespace $(NAMESPACE) ServiceMonitors/$(COMPONENT_NAME)-operator -o=yaml|$(kubectl) delete -f - || true
	$(kubectl) get --namespace $(NAMESPACE) crd/alertmanagers.monitoring.coreos.com -o=yaml|$(kubectl) delete -f - || true
	$(kubectl) get --namespace $(NAMESPACE) crd/prometheuses.monitoring.coreos.com -o=yaml|$(kubectl) delete -f - || true
	$(kubectl) get --namespace $(NAMESPACE) crd/prometheusrules.monitoring.coreos.com -o=yaml|$(kubectl) delete -f - || true
	$(kubectl) get --namespace $(NAMESPACE) crd/servicemonitors.monitoring.coreos.com -o=yaml|$(kubectl) delete -f - || true

clean:
	rm -rf $(HELM_HOME)

-include ../Mk/phonies
