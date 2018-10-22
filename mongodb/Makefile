.DEFAULT_GOAL := deploy

export HELM_HOME ?= $(shell pwd)/.helm

NAMESPACE      ?= mongodb
COMPONENT_NAME ?= mongodb
DOMAIN_NAME    ?= dev.kubernetes.delivery
HOST           := $(COMPONENT_NAME)-mongodb.$(NAMESPACE).svc.cluster.local
kubectl        ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm           ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
CHART          ?= charts/mongodb
CHART_VERSION  ?= 4.3.0
TIMEOUT        ?= 300
CLOUD_KIND     ?= aws

deploy: clean init fetch purge install wait

init:
	@mkdir -p $(HELM_HOME) charts
	@$(helm) init --client-only --upgrade --wait
.PHONY: init

fetch:
	$(helm) fetch \
		--destination charts \
		--untar stable/mongodb \
		--version $(CHART_VERSION)
.PHONY: fetch

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
.PHONY: purge

install:
	-$(kubectl) create namespace $(NAMESPACE)
	$(kubectl) apply -f $(CLOUD_KIND)-storage-class.yaml
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install $(CHART) \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--version $(CHART_VERSION) \
			--replace \
			--values values.yaml \
			--wait
.PHONY: install

undeploy: init
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
.PHONY: undeploy

clean:
	@rm -rf $(HELM_HOME) charts
.PHONY: clean

mongo_ready_container=$(kubectl) get pods -l app=mongodb -o jsonpath='{.items..containerStatuses[?(@.ready==true)].containerID}'
wait:
		$(eval timeout=$(shell echo "`date +%s` + $(TIMEOUT)" | bc ))
		@printf "Waiting for MongoDB pod to become ready "

		@while [ `date +%s` -le "$(timeout)" ]; do \
				if test -n "`$(mongo_ready_container)`"; then \
						printf "\ndone\n"; \
						exit 0; \
				fi; \
				printf "."; \
				sleep 8; \
		done; \
		printf "\nERROR timeout $(TIMEOUT)sec\n"; \
		exit 1
.PHONY: wait
