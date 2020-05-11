.DEFAULT_GOAL := deploy

HELM_OPTS += --values $(abspath values.yaml)

ifeq (2,$(words $(NON_CONFLICTING_AWS_ACCESS_KEY) $(NON_CONFLICTING_AWS_ACCESS_KEY)))
HELM_OPTS += --set 'aws.region=""'
HELM_OPTS += --values $(abspath values-awscreds.yaml)
else

SCRIPT_CMD := $(abspath ..)/bin/aws-role-by-tag
SCRIPT_CMD += --filter "$(CLUSTER_NAME)"
SCRIPT_CMD += --tag superhub.io/role/kind=worker
SCRIPT_CMD += --tag superhub.io/stack/$(DOMAIN_NAME)
ROLE_ARN   := $(shell $(SCRIPT_CMD))
ifeq ($(ROLE_ARN),)
$(warning Cannot find ARM role by tags)
$(warning Trying to run: $(SCRIPT_CMD))
# uncomment for groubleshooting
# $(warning $(shell $(SCRIPT_CMD) -x))
$(error IAM role has not been found!)
endif
# .aws/config will be created if and only if AWS region has been defined
# see: https://github.com/helm/charts/blob/master/stable/external-dns/templates/secret.yaml#L11
HELM_OPTS += --set 'aws.region="$(NON_CONFLICTING_AWS_REGION)"'
HELM_OPTS += --set 'aws.assumeRoleArn=$(ROLE_ARN)'
endif

install:
	$(helm) install $(CHART_DIR) \
		--name $(COMPONENT_NAME) \
		--namespace $(NAMESPACE) \
		--wait $(HELM_OPTS)

.DEFAULT_GOAL: install
.PHONY: install
