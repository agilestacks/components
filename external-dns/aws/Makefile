.DEFAULT_GOAL := deploy

HELM_OPTS += --values $(abspath values.yaml)

terraform := terraform-v0.12
TF_CLI_ARGS                   ?= -no-color -input=false
export TF_DATA_DIR            ?= .terraform/$(DOMAIN_NAME)-$(COMPONENT_NAME)
export TF_VAR_domain_name			:= $(DOMAIN_NAME)
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan
TFSTATE     := $(TF_DATA_DIR)/terraform.tfstate

$(TF_DATA_DIR):
	@rm -rf $@ && mkdir -p $@

init: $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
	-backend=true -reconfigure \
	-backend-config="bucket=$(STATE_BUCKET)" \
	-backend-config="region=$(STATE_REGION)" \
	-backend-config="key=$(DOMAIN_NAME)/$(COMPONENT_NAME)/terraform.tfstate" \
	-backend-config="profile=$(AWS_PROFILE)"

import:
	-$(terraform) import $(TF_CLI_ARGS) aws_iam_role_policy.policy external-dns-$(CLUSTER_NAME):$(CLUSTER_NAME)-default
	-$(terraform) import $(TF_CLI_ARGS) aws_iam_role.role external-dns-$(CLUSTER_NAME)

plan:
	$(terraform) plan $(TF_CLI_ARGS) -refresh=true -out=$(TFPLAN)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

role: init import plan apply

unrole: init import destroy apply

arn:
	$(eval ROLE_ARN := $(shell TF_DATA_DIR=$(TF_DATA_DIR) $(terraform) output role_arn))
	$(eval HELM_OPTS += --set 'aws.assumeRoleArn=$(ROLE_ARN)')
	$(eval HELM_OPTS += --set 'aws.region=$(NON_CONFLICTING_AWS_REGION)')

undeploy:
	-$(helm) delete --purge $(COMPONENT_NAME)

ifeq (2,$(words $(NON_CONFLICTING_AWS_ACCESS_KEY) $(NON_CONFLICTING_AWS_ACCESS_KEY)))
HELM_OPTS += --set 'aws.region='
HELM_OPTS += --values $(abspath values-awscreds.yaml)
else
deploy: role arn
undeploy: unrole
endif

deploy:
	$(helm) ls -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install $(CHART_DIR) \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--wait $(HELM_OPTS)

.DEFAULT_GOAL: deploy
.PHONY: deploy undeploy role unrole arn init plan apply destroy import
