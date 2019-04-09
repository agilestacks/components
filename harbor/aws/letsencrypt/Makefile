.DEFAULT_GOAL := deploy

deploy: $(PULL_SECRET)
undeploy: delete-$(PULL_SECRET)


$(PULL_SECRET):
	- $(kubectl) create secret docker-registry $(PULL_SECRET) \
		--docker-server=$(COMPONENT_NAME).$(INGRESS_FQDN) \
		--docker-username=$(ADMIN_USERNAME) \
		--docker-password="$$ADMIN_PASSWORD"

delete-$(PULL_SECRET):
	- $(kubectl) delete secret $(PULL_SECRET)
