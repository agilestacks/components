.DEFAULT_GOAL := deploy

export HELM_HOME		   ?= $(shell pwd)/.helm

NAMESPACE		?= mongodb
COMPONENT_NAME	?= mongodb
DOMAIN_NAME		?= default
HOST			:= $(COMPONENT_NAME)-mongodb.$(NAMESPACE).svc.cluster.local
kubectl			?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm			?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
CHART			?= charts/mongodb
CHART_VERSION	?= 0.4.27
TIMEOUT			?= 300


deploy: clean init fetch install wait
.PHONY: deploy

init:
	@mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade --wait
	@mkdir -p charts

fetch:
	$(helm) fetch \
		--destination charts \
		--untar stable/mongodb \
		--version $(CHART_VERSION)
.PHONY: fetch

install:
	-$(kubectl) create namespace $(mongodb)
	$(kubectl) apply -f aws-storage-class.yaml
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install $(CHART) \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--version $(CHART_VERSION) \
			--replace \
			--values values.yaml \
			--wait
.PHONY: install

undeploy: init
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
	-$(kubectl) delete -f aws-storage-class.yaml
.PHONY: undeploy

clean:
	@rm -rf $(HELM_HOME)
	@rm -rf charts

mongo_pod=$(kubectl) get pods -l app=mongodb-mongodb -o jsonpath="{range .items[*]}{@.metadata.name}{end}"
wait:
		$(eval timeout=$(shell echo "`date +%s` + $(TIMEOUT)" | bc ))
		@printf "Waiting for mongodb port to be served "

		@while [ `date +%s` -le "$(timeout)" ]; do \
				if $(kubectl) exec -it `$(mongo_pod)` -- mongo --eval "db.help()" "$(HOST):$(PORT)" >& /dev/null; then \
						printf "\ndone\n"; \
						exit 0; \
				fi; \
				printf "."; \
				sleep 8; \
		done; \
		printf "\nERROR timeout $(TIMEOUT)sec\n"; \
		exit 1
.PHONY: wait
