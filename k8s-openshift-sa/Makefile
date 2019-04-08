.DEFAULT_GOAL := deploy

OPENSHIFT_TOKEN ?=
OPENSHIFT_API_URL ?=

ASI_ACCOUNT ?= asi
ASI_ROLE ?= cluster-admin

oc ?= oc 

account:
	$(oc) login $(OPENSHIFT_API_URL) --token=$(OPENSHIFT_TOKEN)
	@if $(oc) get serviceaccount $(ASI_ACCOUNT) ; then \
		echo "Account exists";\
	else \
		echo "Creating a new service account for $(ASI_ACCOUNT)..."; \
		$(oc) create serviceaccount $(ASI_ACCOUNT); \
		$(oc) adm policy add-cluster-role-to-user $(ASI_ROLE) -z $(ASI_ACCOUNT); \
	fi		 
.PHONY: account

secret:
	$(eval SECRET=$(shell $(oc) get serviceaccount $(ASI_ACCOUNT) -o json | \
		jq '.secrets[] | select(.name | contains("token")).name'))
.PHONY: secret

token:
	$(eval TOKEN=$(shell $(oc) get secret $(SECRET) -o json | jq '.data.token'))
.PHONY: token	

output:
	@echo
	@echo Outputs:
	@echo
	@echo sa_token=$(TOKEN)
	@echo
.PHONY: output

deploy: account secret token output

undeploy:
	-oc delete serviceaccount $(ASI_ACCOUNT)
.PHONY: undeploy	

-include ../Mk/phonies
