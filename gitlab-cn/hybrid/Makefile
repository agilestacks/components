.DEFAULT_GOAL := deploy

DOMAIN_NAME    ?= dev.superhub.io
NAMESPACE      ?= gitlab 
kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy:
	$(kubectl) -n $(NAMESPACE) apply -f storageclass.yaml
.PHONY: install

