.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= nats
DOMAIN_NAME    ?= dev.kubernetes.delivery
NAMESPACE      ?= argoproj
CHART          ?= charts/nats
CHART_VERSION  ?= 0.0.6

export HELM_HOME ?= $(shell pwd)/.helm

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

init:
	@mkdir -p $(HELM_HOME) charts
	$(helm) init --client-only --upgrade --wait

fetch:
	$(helm) fetch \
		--destination charts \
		--untar stable/nats \
		--version $(CHART_VERSION)

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

install:
	-$(kubectl) create namespace $(NAMESPACE)
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install $(CHART) \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--version $(CHART_VERSION) \
			--replace \
			--values values.yaml \
			--wait

deploy: clean init fetch purge install
	$(kubectl) apply -f natsboard/deployment.yaml
	$(kubectl) apply -f natsboard/service.yaml
	$(kubectl) apply -f natsboard/ingress.yaml
	$(kubectl) apply -f mon-ingress.yaml

undeploy: init
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

	-$(kubectl) delete -f natsboard/ingress.yaml
	-$(kubectl) delete -f natsboard/service.yaml
	-$(kubectl) delete -f natsboard/deployment.yaml
	-$(kubectl) delete -f mon-ingress.yaml

clean:
	@rm -rf $(HELM_HOME) charts

include ../Mk/phonies
