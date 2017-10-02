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

deploy: clean init fetch wait install

init:
	mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade
	@mkdir -p tmp

wait:
	@for i in $$(seq 1 60); do \
		if $(helm) version; then \
			exit 0; \
		fi; \
		echo "Waiting for Tiller pod is up and running ($$i)..."; \
		sleep 10; \
	done; \
	echo "Timeout waiting for Tiller" \
	exit 1

fetch:
	$(helm) fetch \
			--destination charts \
			--untar $(HELM_CHART)
.PHONY: fetch

install:
ifeq ($(findstring $(COMPONENT_NAME), $(shell $(helm) list -q | xargs)),)
	$(kubectl) create namespace $(NAMESPACE) || true
	$(kubectl) apply -f storage-class.yaml
	$(helm) install charts/$(notdir $(HELM_CHART)) \
			--name $(COMPONENT_NAME) \
			--name-template $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--wait \
			--values $(VALUES_FILE)
endif
.PHONY: install

undeploy: init
ifeq ($(findstring $(COMPONENT_NAME), $(shell $(helm) list -q | xargs)),$(COMPONENT_NAME))
	$(helm) delete $(COMPONENT_NAME) --purge
endif
.PHONY: undeploy

clean:
	rm -rf $(HELM_HOME)
	rm -rf charts/$(notdir $(HELM_CHART))
	rm -rf tmp
