.DEFAULT_GOAL := deploy

NAMESPACE   ?= argoproj
DOMAIN_NAME ?= dev.stacks.delivery
REPO_TYPE   ?= minio
kubectl     ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

namespace:
	- $(kubectl) create namespace $(NAMESPACE)
.PHONY: namespace

deploy: namespace
	$(MAKE) -C $(REPO_TYPE) $@
	$(kubectl) apply -f install.yaml
	$(kubectl) apply -f ingress.yaml
	- $(kubectl) create rolebinding default-admin --clusterrole=admin --serviceaccount=$(NAMESPACE):default
	$(MAKE) -C events $@
.PHONY: deploy

undeploy:
	$(MAKE) -C events $@
	- $(kubectl) delete rolebinding default-admin
	- $(kubectl) delete -f install.yaml
	- $(kubectl) delete -f ingress.yaml
	$(MAKE) -C $(REPO_TYPE) $@
.PHONY: undeploy

output:
	$(MAKE) -C $(REPO_TYPE) $@
	@ echo
.PHONY: tf_output
