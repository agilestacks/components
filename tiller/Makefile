.DEFAULT_GOAL := deploy

export NAMESPACE    ?= kube-system
export DOMAIN_NAME  ?= default
export kubectl      ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm         ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="$(NAMESPACE)"

deploy: init wait
.PHONY: deploy

init:
	$(helm) init --upgrade --service-account tiller
.PHONY: init

undeploy:
	$(helm) reset --force
.PHONY: undeploy

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
.PHONY: wait
