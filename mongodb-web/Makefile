.DEFAULT_GOAL := deploy

DOMAIN_NAME ?= dev.kubernetes.delivery
NAMESPACE   ?= mongodb

TIMEOUT ?= 300

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy: kubernetes wait

kubernetes:
	-$(kubectl) create namespace $(NAMESPACE)
	$(kubectl) apply -f service.yaml
	$(kubectl) apply -f ingress.yaml
	$(kubectl) apply -f deployment.yaml

mongo_ready_container=$(kubectl) get pods -l 'project=mongodb-dashboard,qualifier=master' --output=jsonpath='{.items..containerStatuses[?(@.ready==true)].containerID}'
wait:
	$(eval timeout=$(shell echo "`date +%s` + $(TIMEOUT)" | bc ))
	@echo "Waiting for MongoDB Dashboard pod is up and running"

	@while [ `date +%s` -le "$(timeout)" ]; do \
		if test -n "`$(mongo_ready_container)`"; then \
			echo done; \
			exit 0; \
		fi; \
		echo 'still waiting'; \
		sleep 8; \
	done; \
	echo "ERROR timeout $(TIMEOUT)sec"; \
	exit 1

undeploy:
	-$(kubectl) delete -f ingress.yaml
	-$(kubectl) delete -f service.yaml
	-$(kubectl) delete -f deployment.yaml

-include ../Mk/phonies
