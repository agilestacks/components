.DEFAULT_GOAL := deploy

export NAMESPACE    ?= kube-system
export DOMAIN_NAME  ?= default
export kubectl      ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm         ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="$(NAMESPACE)"

deploy: wait_rbac init wait
.PHONY: deploy

init:
	$(kubectl) apply -f tiller-rbac.yaml
	$(helm) init --upgrade --service-account tiller
.PHONY: init

undeploy:
	$(helm) reset --force
	$(kubectl) delete -f tiller-rbac.yaml | true
.PHONY: undeploy

wait:
	@for i in $$(seq 1 60); do \
		if $(helm) version; then \
			echo " done" \
			exit 0; \
		fi; \
		printf "."; \
		sleep 10; \
	done; \
	echo "Timeout waiting for Tiller" \
	exit 1
.PHONY: wait

wait_rbac:
	@for i in $$(seq 1 60); do \
		if $(kubectl) get sa ; then \
			echo " done" \
			exit 0; \
		fi; \
		printf "."; \
		sleep 10; \
	done; \
	echo "Timeout waiting for admin RBAC roles to be deployed" \
	exit 1
