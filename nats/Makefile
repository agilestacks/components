.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= nats
DOMAIN_NAME    ?= test.dev.superhub.io
NAMESPACE      ?= argoproj
CHART          ?= bitnami/nats
CHART_VERSION  ?= 4.3.12

export HELM_HOME ?= $(shell pwd)/.helm

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init fetch purge install natsboard

init:
	@mkdir -p $(HELM_HOME) charts
	$(helm) init --client-only --upgrade --wait

fetch:
	$(helm) repo add bitnami https://charts.bitnami.com/bitnami
	$(helm) fetch \
		--destination charts \
		--untar $(CHART) \
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
			--values values.yaml \
			--wait

natsboard:
	$(kubectl) apply -f natsboard/deployment.yaml
	$(kubectl) apply -f natsboard/service.yaml
	$(kubectl) apply -f natsboard/ingress.yaml
	$(kubectl) apply -f mon-ingress.yaml
.PHONY: natsboard

undeploy: init unnatsboard
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

unnatsboard:
	-$(kubectl) delete -f natsboard/ingress.yaml
	-$(kubectl) delete -f natsboard/service.yaml
	-$(kubectl) delete -f natsboard/deployment.yaml
	-$(kubectl) delete -f mon-ingress.yaml
.PHONY: unnatsboard

clean:
	@rm -rf $(HELM_HOME) charts

-include ../Mk/phonies
