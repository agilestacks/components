.DEFAULT_GOAL := deploy

DOMAIN_NAME ?= dev.stacks.delivery
NAMESPACE   ?= argoproj
REPO_TYPE   ?= minio

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

namespace:
	- $(kubectl) create namespace $(NAMESPACE)

deploy: namespace
	$(MAKE) -C $(REPO_TYPE) $@
	-$(kubectl) apply -f crd.yaml
	$(kubectl) apply -f install.yaml
	$(kubectl) apply -f ingress.yaml
	- $(kubectl) create rolebinding default-admin --clusterrole=admin --serviceaccount=$(NAMESPACE):default
	$(MAKE) -C events $@

undeploy:
	$(MAKE) -C events $@
	- $(kubectl) delete rolebinding default-admin
	- $(kubectl) delete -f install.yaml
	- $(kubectl) delete -f ingress.yaml
	$(MAKE) -C $(REPO_TYPE) $@

output:
	$(MAKE) -C $(REPO_TYPE) $@
	@ echo

-include ../Mk/phonies
