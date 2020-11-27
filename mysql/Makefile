.DEFAULT_GOAL := deploy

HELM_HOME   := $(abspath .helm)
CHART_NAME  := stable/mysql
CHART_DIR   := $(HELM_HOME)/charts/$(notdir $(CHART_NAME))
export HELM_HOME

kubectl   := kubectl --context="$(DOMAIN_NAME)" -n "$(NAMESPACE)"
helm      := helm2 --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
HELM_OPTS += --values $(abspath $(CHART_DIR)/values.yaml)
HELM_OPTS += --values $(abspath values.yaml)

ifneq (,$(DB_NAME))
HELM_OPTS += --set 'mysqlDatabase=$(DB_NAME)'
endif

ifneq (,$(DB_USER))
HELM_OPTS += --set 'mysqlUser=$(DB_USER)'
endif

ifneq (,$(DB_PASSWORD))
HELM_OPTS += --set 'mysqlPassword=$(DB_PASSWORD)'
else
HELM_OPTS += --set 'mysqlAllowEmptyPassword=true'
endif

ifneq (,$(ROOT_PASSWORD))
HELM_OPTS += --set 'mysqlRootPassword=$(ROOT_PASSWORD)'
else
HELM_OPTS += --set 'allowEmptyRootPassword=true'
endif

ifeq (0,$(shell $(kubectl) get pvc $(COMPONENT_NAME) >/dev/null 2>&1 | echo $?))
HELM_OPTS += --set 'persistence.existingClaim=$(COMPONENT_NAME)'
endif

namespace:
	$(kubectl) get namespace $(NAMESPACE) || \
		$(kubectl) create namespace $(NAMESPACE)

deploy: $(CHART_DIR) namespace
	@ echo "Installing '$(COMPONENT_NAME)' from helm chart at: $(CHART_DIR)"
	$(helm) --namespace $(NAMESPACE) ls -q | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install $(CHART_DIR) \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--wait $(HELM_OPTS)

undeploy: $(CHART_DIR)
	$(helm) ls -q -a | grep -E '^$(COMPONENT_NAME)$$' \
		&& $(helm) delete --purge $(COMPONENT_NAME)

$(HELM_HOME):
	mkdir -p $@
	$(helm) init --client-only --upgrade --wait

$(CHART_DIR): $(HELM_HOME)
	rm -rf $@
	$(helm) fetch $(CHART_NAME) \
		--version=$(CHART_VERSION) \
		--untar --untardir $(dir $@)

.SILENT:   undeploy $(HELM_HOME) deploy
.IGNORE:   undeploy namespace
.PRECIOUS: $(CHART_DIR)
.PHONY: deploy undeploy
