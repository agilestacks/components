.DEFAULT_GOAL := deploy

DOMAIN_NAME ?= test.dev.superhub.io
NAME2       := $(shell echo $(TF_VAR_name) | sed -E -e 's/[^[:alnum:]]+/-/g' | cut -c1-50)

STATE_BUCKET ?= terraform.agilestacks.com
STATE_REGION ?= us-east-1

export AWS_DEFAULT_REGION ?= us-east-2

export TF_DATA_DIR ?= .terraform/$(TF_VAR_name)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log

terraform   ?= terraform-v0.12
TF_CLI_ARGS ?= -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan

# export TF_VAR_subnet_ids := $(shell echo '$(SUBNET_IDS)' | jq -cR 'split(",")')

deploy: init import plan apply

$(TF_DATA_DIR):
	@rm -rf $@ && mkdir -p $@

init: $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(DOMAIN_NAME)/eks-fargate/$(TF_VAR_name)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"

plan:
	$(terraform) plan $(TF_CLI_ARGS) -out=$(TFPLAN)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)

import:
	-$(terraform) import $(TF_CLI_ARGS) aws_iam_role.fargate eks-fargate-$(NAME2)
	-$(terraform) import $(TF_CLI_ARGS) aws_eks_fargate_profile.main $(TF_VAR_cluster_name):$(TF_VAR_short_name)

output:
	@$(terraform) output -no-color

undeploy: init import destroy apply

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

-include ../Mk/phonies
