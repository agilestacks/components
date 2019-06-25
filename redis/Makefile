.DEFAULT_GOAL := deploy

COMPONENT_NAME   ?= redis
DOMAIN_NAME      ?= dev.kubernetes.delivery
NAMESPACE 	     ?= redis
HA_ENABLED       ?= false
CHART_VERSION    ?= 6.1.4
HA_CHART_VERSION ?= 3.3.0

export HELM_HOME ?= $(shell pwd)/.helm

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

ifeq ($(HA_ENABLED),true)
HELM_CHART=stable/redis-ha
VALUES_FILE=values-ha.yaml
CHART_VERSION=$(HA_CHART_VERSION)
else
HELM_CHART=stable/redis
VALUES_FILE=values.yaml
endif

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
	$(kubectl) apply -f namespace.yaml
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install charts/$(notdir $(HELM_CHART)) \
			--name $(COMPONENT_NAME) \
			--name-template $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--wait \
			--values $(VALUES_FILE) \
			--version $(CHART_VERSION)

output:
	@if ! grep '^usePassword: true' values.yaml; then \
		echo; \
		echo Outputs:; \
		echo password=; \
		echo; \
		exit 0; \
	fi; \
	secret=$$(echo $(COMPONENT_NAME) | grep redis); \
	echo $${secret:=$(COMPONENT_NAME)-redis}; \
	for i in $$(seq 1 60); do \
		if password=$$($(kubectl) get secret $$secret -o jsonpath='{.data.redis-password}'); then \
			echo; \
			echo Outputs:; \
			echo password=$$password | $(HUB) util otp; \
			echo; \
			exit 0; \
		fi; \
		sleep 1; \
	done; \
	exit 1

undeploy: init
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

clean:
	rm -rf $(HELM_HOME) charts/$(notdir $(HELM_CHART))

-include ../Mk/phonies
