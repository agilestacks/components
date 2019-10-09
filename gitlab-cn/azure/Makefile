.DEFAULT_GOAL := install

TF_VAR_domain_name    ?= dev.superhub.io
TF_VAR_namespace      ?= gitlab 
kubectl ?= kubectl --context="$(TF_VAR_domain_name)" --namespace="$(TF_VAR_namespace)"

install:
	$(kubectl) -n $(TF_VAR_namespace) apply -f storageclass.yaml | true
.PHONY: install

dns:
	./add-dns-entry.sh
.PHONE: dns
