.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= graphite
DOMAIN_NAME    ?= test.dev.superhub
NAMESPACE      ?= graphite
HELM_CHART     ?= kiwigrid/graphite
CHART_VERSION  ?= 0.7.0
VALUES_FILE    ?= values.yaml

export HELM_HOME ?= $(shell pwd)/.helm

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm2 --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

# if ingress-tls in provides then tls-host-controler will manage TLS block for us
# else install our own TLS block
ifeq (,$(filter tls-ingress,$(HUB_PROVIDES)))
	INGRESS_TLS_VALUES:=--values values-tls.yaml
endif

deploy: clean init fetch purge install

init:
	@mkdir -p $(HELM_HOME) charts
	$(helm) init --client-only --upgrade

fetch:
	$(helm) repo add kiwigrid https://kiwigrid.github.io
	$(helm) fetch \
		--destination charts \
		--untar $(HELM_CHART) \
		--version $(CHART_VERSION)

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

install:
	-$(kubectl) create ns $(NAMESPACE)
	if ! $(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$'; then \
		$(helm) install charts/$(notdir $(HELM_CHART)) \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--wait \
			--values $(VALUES_FILE) \
			$(INGRESS_TLS_VALUES) \
			--version $(CHART_VERSION); \
	else \
		$(MAKE) upgrade; \
	fi

upgrade:
	$(helm) upgrade $(COMPONENT_NAME) charts/$(notdir $(HELM_CHART)) \
		--namespace $(NAMESPACE) \
		--wait \
		--values $(VALUES_FILE) \
		$(INGRESS_TLS_VALUES) \
		--version $(CHART_VERSION)

undeploy: init
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

clean:
	rm -rf $(HELM_HOME) charts/$(notdir $(HELM_CHART))

-include ../Mk/phonies
