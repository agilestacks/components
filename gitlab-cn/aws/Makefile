.DEFAULT_GOAL := install

DOMAIN_NAME    ?= dev.superhub.io
NAMESPACE      ?= gitlab 
kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

install:
	$(kubectl) -n $(NAMESPACE) apply -f storageclass.yaml
.PHONY: install

dns:
	@echo "DNS for AWS created by TF, skipping"
.PHONE: dns
