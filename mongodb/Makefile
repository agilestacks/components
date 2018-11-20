.DEFAULT_GOAL := deploy

export HELM_HOME ?= $(shell pwd)/.helm

COMPONENT_NAME ?= mongodb
DOMAIN_NAME    ?= dev.kubernetes.delivery
NAMESPACE      ?= mongodb
CLOUD_KIND     ?= aws
CHART          ?= charts/mongodb
CHART_VERSION  ?= 4.3.0

TIMEOUT ?= 300

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init fetch purge install wait

init:
	@mkdir -p $(HELM_HOME) charts
	@$(helm) init --client-only --upgrade --wait

fetch:
	$(helm) fetch \
		--destination charts \
		--untar stable/mongodb \
		--version $(CHART_VERSION)

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

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

undeploy: init
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

clean:
	@rm -rf $(HELM_HOME) charts

mongo_ready_container=$(kubectl) get pods -l app=mongodb -o jsonpath='{.items..containerStatuses[?(@.ready==true)].containerID}'
wait:
		$(eval timeout=$(shell echo "`date +%s` + $(TIMEOUT)" | bc ))
		@echo "Waiting for MongoDB pod to become ready"

		@while [ `date +%s` -le "$(timeout)" ]; do \
				if test -n "`$(mongo_ready_container)`"; then \
						echo done; \
						exit 0; \
				fi; \
				printf "."; \
				sleep 8; \
		done; \
		echo "ERROR timeout $(TIMEOUT)sec"; \
		exit 1

include ../Mk/phonies
