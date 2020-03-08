.DEFAULT_GOAL := deploy

aws-role-by-tag  := $(abspath ..)/bin/aws-role-by-tag
ROLE_ARN         := $(shell $(aws-role-by-tag) \
							--filter "$(CLUSTER_NAME)" \
							--tag superhub.io/role/kind=worker \
							--tag superhub.io/stack/$(DOMAIN_NAME))

ifeq ($(ROLE_ARN),)
$(error Cannot find role by tags: superhub.io/stack/$(DOMAIN_NAME) and superhub.io/role/kind=worker)
endif

HELM_OPTS += --values $(abspath values.yaml)
HELM_OPTS += --set 'aws.assumeRoleArn=$(ROLE_ARN)'

install:
	$(helm) install $(CHART_DIR) \
		--name $(COMPONENT_NAME) \
		--namespace $(NAMESPACE) \
		--wait $(HELM_OPTS)

.DEFAULT_GOAL: install
.PHONY: install
