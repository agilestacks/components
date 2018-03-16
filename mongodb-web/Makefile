.DEFAULT_GOAL := deploy

export DOMAIN_NAME ?= default
export NAMESPACE   ?= mongodb

TIMEOUT     ?= 300
kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"


deploy:
	-$(kubectl) create namespace $(NAMESPACE)
	$(kubectl) apply -f deployment.yaml

	$(MAKE) wait
.PHONY: deploy

wait:
	$(eval timeout=$(shell echo "`date +%s` + $(TIMEOUT)" | bc ))
	$(eval get_pod=$(kubectl) get pods -l 'project=mongodb-dashboard,qualifier=master' --output=jsonpath='{.items..containerStatuses[?(@.ready==true)].containerID}')
	@printf "Waiting for MongoDB Dashboard pod is up and running "

	@while [ `date +%s` -le "$(timeout)" ]; do \
		if [[ `$(get_pod)` ]]; then \
			echo " done"; \
			exit 0; \
		fi; \
		printf "."; \
		sleep 8; \
	done; \
	echo " ERROR timeout $(TIMEOUT)sec"; \
	exit 1

undeploy:
	-$(kubectl) delete -f deployment.yaml
.PHONY: undeploy
