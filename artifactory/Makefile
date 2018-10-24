.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= artifactory
DOMAIN_NAME    ?= dev.stacks.delivery
STATE_BUCKET   ?= terraform.agilestacks.com
STATE_REGION   ?= us-east-1

export AWS_DEFAULT_REGION ?= us-east-2
export TF_LOG             ?= debug
export TF_LOG_PATH        ?= .terraform/$(DOMAIN_NAME).log
export TF_OPTS            ?= -no-color
export TF_UPDATE          ?= -update
export TF_VAR_name        := $(COMPONENT_NAME)

terraform ?= terraform
TFPLAN ?= $(notdir $(COMPONENT_NAME)).tfplan

deploy: init import plan apply

init:
	@echo "Init"
.PHONY: init

get:
	@echo "Get"
.PHONY: get

plan:
	@echo "Plan"
.PHONY: plan

apply:
	@echo "Apply"
.PHONY: apply

undeploy: init
	@echo "Undeploy"
.PHONY: undeploy

import:
	@echo "Import"
.PHONY: import
