.DEFAULT_GOAL := deploy

HELM_OPTS += --values $(abspath values.yaml)

deploy:
	$(helm) install $(CHART_DIR) \
		--name $(COMPONENT_NAME) \
		--namespace $(NAMESPACE) \
		--wait \
		$(HELM_OPTS)

undeploy:
	-$(helm) delete --purge $(COMPONENT_NAME)

.DEFAULT_GOAL: install
.PHONY: install
