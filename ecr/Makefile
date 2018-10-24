.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= ecr
DOMAIN_NAME    ?= dev.stacks.delivery
STATE_BUCKET   ?= terraform.agilestacks.com
STATE_REGION   ?= us-east-1

export AWS_DEFAULT_REGION ?= us-east-2
export TF_LOG             ?= debug
export TF_LOG_PATH        ?= .terraform/$(DOMAIN_NAME).log
export TF_OPTS            ?= -no-color
export TF_UPDATE          ?= -update
export TF_VAR_name        := $(COMPONENT_NAME)

terraform ?= terraform-v0.11
TFPLAN ?= $(notdir $(COMPONENT_NAME)).tfplan

deploy: init import plan apply

init:
	@mkdir -p .terraform
	$(terraform) init -get=true $(TF_CMD_OPTS) -reconfigure -force-copy  \
		-backend=true -input=false \
		-backend-config="bucket=$(STATE_BUCKET)" \
		-backend-config="region=$(STATE_REGION)" \
		-backend-config="key=$(DOMAIN_NAME)/ecr/$(notdir $(COMPONENT_NAME))/terraform.tfstate" \
		-backend-config="profile=$(AWS_PROFILE)"
.PHONY: init

get:
	$(terraform) get $(TF_UPDATE)
.PHONY: get

plan:
	$(terraform) plan $(TF_OPTS) -refresh=true -module-depth=-1 -out=$(TFPLAN)
.PHONY: plan

apply:
	$(terraform) apply $(TF_OPTS) -Xshadow=false $(TFPLAN)
.PHONY: apply

undeploy: init
	$(MAKE) plan TF_OPTS=-destroy
	$(MAKE) apply
.PHONY: undeploy

import:
	-$(terraform) import $(TF_OPTS) module.ecr.aws_ecr_repository.main $(TF_VAR_name) \
		2>/dev/null
.PHONY: import
