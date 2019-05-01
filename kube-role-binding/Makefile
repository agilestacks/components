.DEFAULT_GOAL := deploy

kubectl ?= kubectl --context="$(DOMAIN_NAME)"

IDENTITY_TYPE ?= user
IDENTITY_NAME ?= client

ROLE_TYPE ?= clusterrole
ROLE_NAME ?= cluster-admin

BINDING_TYPE ?= clusterrolebinding

deploy:
	-$(kubectl) create $(BINDING_TYPE) $(IDENTITY_NAME)-$(ROLE_NAME)-binding \
		--$(ROLE_TYPE)=$(ROLE_NAME) --$(IDENTITY_TYPE)=$(IDENTITY_NAME)

undeploy:
	-$(kubectl) delete $(BINDING_TYPE) $(IDENTITY_NAME)-$(ROLE_NAME)-binding
			