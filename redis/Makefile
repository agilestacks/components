.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export COMPONENT_NAME      ?= redis
export NAMESPACE 		   ?= redis
export DOMAIN_NAME         ?= default
export kubectl     		   ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm        		   ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
export HA_ENABLED          ?= false

ifeq ($(HA_ENABLED),true)
HELM_CHART=stable/redis-ha
VALUES_FILE=values-ha.yaml
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
			--untar $(HELM_CHART)
.PHONY: fetch

install:
	$(kubectl) apply -f namespace.yaml
	$(kubectl) apply -f storage-class.yaml
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install charts/$(notdir $(HELM_CHART)) \
			--name $(COMPONENT_NAME) \
			--name-template $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--wait \
			--values $(VALUES_FILE)
.PHONY: install

output:
	@echo
	@echo Outputs:
	@echo password = $(shell $(kubectl) get secret $(COMPONENT_NAME)-redis -o jsonpath='{.data.redis-password}' | base64 --decode)
.PHONY: outputs

undeploy: init
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
.PHONY: undeploy

clean:
	rm -rf $(HELM_HOME)
	rm -rf charts/$(notdir $(HELM_CHART))
	rm -rf tmp
