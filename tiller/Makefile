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
	echo "Waiting for Tiller pod is up and running "; \
	@for i in $$(seq 1 60); do \
		if $(helm) version; then \
			printf ' Done\n'
			exit 0; \
		fi; \
		printf '.'; \
		sleep 10; \
	done; \
	printf "Timeout after 60 retries \n" \
	exit 1
.PHONY: wait

wait_rbac:
	@for i in $$(seq 1 60); do \
		if $(kubectl) get sa ; then \
			exit 0; \
		fi; \
		echo "Waiting for admin RBAC roles to be created ($$i)..."; \
		sleep 10; \
	done; \
	echo "Timeout waiting for admin RBAC roles to be deployed" \
	exit 1
