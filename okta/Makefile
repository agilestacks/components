.DEFAULT_GOAL := deploy

export TF_VAR_name   ?= test
export DOMAIN_NAME   ?= default 

export kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"


deploy:
	sh ./okta-app.sh create

.PHONY: deploy

output:
	@echo Outputs:

.PHONY: output

undeploy:
	sh ./okta-app.sh create

.PHONY: undeploy
