HELM_OPTS += --values $(abspath .)/values.yaml

install: 
	$(helm) install $(CHART_DIR) \
		--name $(COMPONENT_NAME) \
		--namespace $(NAMESPACE) \
		--wait $(HELM_OPTS)

.DEFAULT_GOAL: install
.PHONY: install
