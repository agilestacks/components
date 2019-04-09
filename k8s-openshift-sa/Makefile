.DEFAULT_GOAL := deploy

OPENSHIFT_TOKEN ?=
API_ENDPOINT ?=

ASI_ACCOUNT ?= asi
ASI_ROLE ?= cluster-admin

DOMAIN_NAME ?= metal.kubernetes.delivery

oc ?= oc

account:
	$(oc) login $(API_ENDPOINT) --token=$(OPENSHIFT_TOKEN)
	@if $(oc) get serviceaccount $(ASI_ACCOUNT) ; then \
		echo "Account exists"; \
	else \
		echo "Creating a new service account for $(ASI_ACCOUNT)..."; \
		$(oc) create serviceaccount $(ASI_ACCOUNT) -n default; \
		$(oc) adm policy add-cluster-role-to-user $(ASI_ROLE) -z $(ASI_ACCOUNT); \
	fi		 
.PHONY: account

secret:
	$(eval SECRET=$(shell $(oc) get serviceaccount $(ASI_ACCOUNT) -o json | \
		jq '.secrets[] | select(.name | contains("token")).name'))
.PHONY: secret

token:
	$(eval TOKEN_BASE64=$(shell $(oc) get secret $(SECRET) -o json | \
		jq '.data.token'))
.PHONY: token

decode:
	$(eval TOKEN=$(shell echo $(TOKEN_BASE64) | base64 --decode))
.PHONY: decode	

output:
	@echo
	@echo Outputs:
	@echo
	@echo sa_token=$(TOKEN)
	@echo
.PHONY: output

deploy: account secret token decode output

undeploy:
	-oc --context=$(DOMAIN_NAME) delete serviceaccount $(ASI_ACCOUNT) -n default
.PHONY: undeploy	

-include ../Mk/phonies
