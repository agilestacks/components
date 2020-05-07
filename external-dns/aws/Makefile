.DEFAULT_GOAL := deploy

ifeq ($(AWS_DNS_CREDENTIALS_ENABLED),false)
aws-role-by-tag  := $(abspath ..)/bin/aws-role-by-tag
ROLE_ARN         := $(shell $(aws-role-by-tag) \
							--filter "$(CLUSTER_NAME)" \
							--tag superhub.io/role/kind=worker \
							--tag superhub.io/stack/$(DOMAIN_NAME))
endif

ifeq ($(AWS_DNS_CREDENTIALS_ENABLED),false)
ifeq ($(ROLE_ARN),)
$(error Cannot find role by tags: superhub.io/stack/$(DOMAIN_NAME) and superhub.io/role/kind=worker)
endif
endif

HELM_OPTS += --values $(abspath values.yaml)

ifeq ($(AWS_DNS_CREDENTIALS_ENABLED),false)
HELM_OPTS += --set 'aws.assumeRoleArn=$(ROLE_ARN)'
else
HELM_OPTS += --values $(abspath values-external.yaml)
endif

install:
	$(helm) install $(CHART_DIR) \
		--name $(COMPONENT_NAME) \
		--namespace $(NAMESPACE) \
		--wait $(HELM_OPTS)

.DEFAULT_GOAL: install
.PHONY: install
