.DEFAULT_GOAL := install

kubectl := kubectl --context="$(TF_VAR_domain_name)" --namespace="$(TF_VAR_namespace)"

install:
	$(kubectl) apply -f storageclass.yaml
.PHONY: install

dns:
	@echo "DNS for AWS created by TF, skipping"
.PHONE: dns
