.DEFAULT_GOAL := deploy

export HELM_HOME ?= $(shell pwd)/.helm

NAMESPACE       ?= argoproj
COMPONENT_NAME  ?= nats
DOMAIN_NAME     ?= default
kubectl         ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm            ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
CHART           ?= charts/nats
CHART_VERSION   ?= 0.0.6

$(HELM_HOME):
	mkdir -p "$@"

charts:
	mkdir -p "$@"

namespace:
	- $(kubectl) create namespace $(NAMESPACE)
.PHONY: namespace

init: $(HELM_HOME) charts
	@ $(helm) init --client-only --upgrade --wait
.PHONY: init

fetch:
	$(helm) fetch \
		--destination charts \
		--untar stable/nats \
		--version $(CHART_VERSION)
.PHONY: fetch

install: namespace
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install $(CHART) \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--version $(CHART_VERSION) \
			--replace \
			--values values.yaml \
			--wait
.PHONY: install

deploy: clean init fetch install
	$(kubectl) apply -f natsboard/deployment.yaml
	$(kubectl) apply -f natsboard/service.yaml
	$(kubectl) apply -f natsboard/ingress.yaml
	$(kubectl) apply -f mon-ingress.yaml
.PHONY: deploy

undeploy: init
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

	- $(kubectl) delete -f natsboard/ingress.yaml
	- $(kubectl) delete -f natsboard/service.yaml
	- $(kubectl) delete -f natsboard/deployment.yaml
	- $(kubectl) delete -f mon-ingress.yaml
.PHONY: undeploy

clean:
	@ rm -rf $(HELM_HOME)
	@ rm -rf charts
.PHONY: clean
