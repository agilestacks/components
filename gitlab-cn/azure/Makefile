.DEFAULT_GOAL := install

DOMAIN_NAME    ?= dev.superhub.io
NAMESPACE      ?= gitlab 
kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

install:
	$(kubectl) -n $(NAMESPACE) apply -f storageclass.yaml | true
.PHONY: install

dns:
	./add-dns-entry.sh
.PHONE: dns
