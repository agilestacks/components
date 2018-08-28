.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
COMPONENT_NAME   ?= redis
NAMESPACE 	     ?= redis
DOMAIN_NAME      ?= default
HA_ENABLED       ?= false
CHART_VERSION    ?= 1.1.15
kubectl          ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm             ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
HA_CHART_VERSION ?= 2.1.1

CLOUD_KIND ?= aws

ifeq ($(HA_ENABLED),true)
HELM_CHART=stable/redis-ha
VALUES_FILE=values-ha.yaml
CHART_VERSION=$(HA_CHART_VERSION)
else
HELM_CHART=stable/redis
VALUES_FILE=values.yaml
endif

deploy: clean init fetch install output
.PHONY: deploy

init:
	mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade
	@mkdir -p tmp

fetch:
	$(helm) fetch \
			--destination charts \
			--untar $(HELM_CHART) \
			--version $(CHART_VERSION)
.PHONY: fetch

install:
	-$(kubectl) create namespace $(NAMESPACE)
	$(kubectl) apply -f $(CLOUD_KIND)-storage-class.yaml
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install charts/$(notdir $(HELM_CHART)) \
			--name $(COMPONENT_NAME) \
			--name-template $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--wait \
			--values $(VALUES_FILE) \
			--version $(CHART_VERSION)
.PHONY: install

output:
	@if ! grep '^usePassword: true' values.yaml; then \
		echo; \
		echo Outputs:; \
		echo password=; \
		echo; \
		exit 0; \
	fi; \
	for i in $$(seq 1 60); do \
		if password=$$($(kubectl) get secret $(COMPONENT_NAME)-redis -o jsonpath='{.data.redis-password}'); then \
			echo; \
			echo Outputs:; \
			echo password=$$password; \
			echo; \
			exit 0; \
		fi; \
		sleep 1; \
	done; \
	exit 1
.PHONY: outputs

undeploy: init
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
	#-$(kubectl) delete -f $(CLOUD_KIND)-storage-class.yaml
.PHONY: undeploy

clean:
	rm -rf $(HELM_HOME)
	rm -rf charts/$(notdir $(HELM_CHART))
	rm -rf tmp
