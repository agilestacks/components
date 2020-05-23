.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= kubecost
DOMAIN_NAME    ?= test.dev.superhub.io
NAMESPACE 	   ?= kubecost
HELM_REPO_URL  ?= https://kubecost.github.io/cost-analyzer/
HELM_REPO_NAME ?= kubecost
HELM_CHART     ?= $(HELM_REPO_NAME)/cost-analyzer
VERSION        ?= v1.59.0

export HELM_HOME ?= $(shell pwd)/.helm

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init fetch purge install

init:
	@mkdir -p $(HELM_HOME) charts
	$(helm) init --client-only --upgrade

fetch:
	$(helm) repo add kubecost $(HELM_REPO_URL)
	$(helm) fetch \
		--destination charts \
		--untar $(HELM_CHART) \
		--version $(VERSION)

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' \
		&& $(helm) delete --purge $(COMPONENT_NAME) \
		|| exit 0

install:
	$(kubectl) apply -f namespace.yaml

	if ! $(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$'; then \
		$(helm) install charts/$(notdir $(HELM_CHART)) \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--wait \
			--values values.yaml \
			$(if $(KUBECOST_TOKEN),--set kubecostToken="$(KUBECOST_TOKEN)") \
			--version $(VERSION); \
	else \
		$(MAKE) upgrade; \
	fi

	$(kubectl) apply -f ingress.yaml


upgrade:
	$(helm) upgrade $(COMPONENT_NAME) charts/$(notdir $(HELM_CHART)) \
		--namespace $(NAMESPACE) \
		--wait \
		--values values.yaml \
		--version $(VERSION)


undeploy: init
	$(kubectl) delete -f ingress.yaml
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

clean:
	rm -rf $(HELM_HOME) charts/$(notdir $(HELM_CHART))

-include ../Mk/phonies
