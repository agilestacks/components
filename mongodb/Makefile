.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= mongodb
DOMAIN_NAME    ?= test.dev.superhub.io
NAMESPACE      ?= mongodb
CHART          ?= bitnami/mongodb
CHART_VERSION  ?= 7.13.0

export HELM_HOME ?= $(shell pwd)/.helm

TIMEOUT ?= 300

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init fetch purge install wait

init:
	@mkdir -p $(HELM_HOME) charts
	@$(helm) init --client-only --upgrade --wait

fetch:
	$(helm) repo add bitnami https://charts.bitnami.com/bitnami
	$(helm) fetch \
		--destination charts \
		--untar $(CHART) \
		--version $(CHART_VERSION)

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

install:
	-$(kubectl) create namespace $(NAMESPACE)
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install $(CHART) \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--version $(CHART_VERSION) \
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
	@while test `date +%s` -le "$(timeout)"; do \
		if test -n "`$(mongo_ready_container)`"; then \
			echo done; \
			exit 0; \
		fi; \
		echo 'still waiting'; \
		sleep 8; \
	done; \
	echo "ERROR timeout $(TIMEOUT)sec"; \
	exit 1

-include ../Mk/phonies
