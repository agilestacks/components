.DEFAULT_GOAL := deploy

install:
	$(helm) ls -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install $(CHART_DIR) \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--wait $(HELM_OPTS)

.PHONY: install
