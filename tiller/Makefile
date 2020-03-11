.DEFAULT_GOAL := deploy

DOMAIN_NAME ?= dev.kubernetes.delivery
NAMESPACE   ?= kube-system

kubectl := kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    := helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="$(NAMESPACE)"

deploy: wait_rbac init wait

init:
	$(kubectl) apply -f tiller-rbac.yaml
	$(helm) init --upgrade --service-account tiller

undeploy:
	$(helm) reset --force
	-$(kubectl) delete -f tiller-rbac.yaml

wait:
	@for i in $$(seq 1 18); do \
		if $(helm) --tiller-connection-timeout 10 version; then \
			exit 0; \
		fi; \
		echo "Waiting for Tiller pod is up and running ($$i)..."; \
		sleep 10; \
	done; \
	echo "Timeout waiting for Tiller"; \
	exit 1

wait_rbac:
	@for i in $$(seq 1 60); do \
		if $(kubectl) get sa >/dev/null; then \
			exit 0; \
		fi; \
		echo "Waiting for admin RBAC roles to be created ($$i)..."; \
		sleep 10; \
	done; \
	echo "Timeout waiting for admin RBAC roles to be deployed"; \
	exit 1
.PHONY: wait_rbac

-include ../Mk/phonies
