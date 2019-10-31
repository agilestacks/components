.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= kafka
DOMAIN_NAME    ?= dev.kubernetes.delivery
NAMESPACE      ?= kafka
CHART_VERSION  ?= 0.20.1
REPO           ?= kafka
export HELM_HOME ?= $(shell pwd)/.helm

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init fetch purge install

init:
	@mkdir -p $(HELM_HOME) charts
	$(helm) init --client-only --upgrade

fetch:
	$(helm) repo add $(REPO) http://storage.googleapis.com/kubernetes-charts-incubator

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

install:
	$(kubectl) apply -f namespace.yaml
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install $(REPO)/kafka \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--values values.yaml

undeploy: init
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

clean:
	rm -rf $(HELM_HOME) charts

-include ../Mk/phonies
