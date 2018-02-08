.DEFAULT_GOAL := deploy

export COMPONENT_NAME     ?= ecr
export TF_VAR_name        := $(COMPONENT_NAME)
export DOMAIN_NAME        ?= dev.stacks.delivery
export AWS_PROFILE        ?= default
export AWS_DEFAULT_REGION ?= us-east-2

export TF_LOG             ?= debug
export TF_LOG_PATH        ?= .terraform/$(DOMAIN_NAME).log
export TF_OPTS            ?= -no-color
export TF_UPDATE          ?= -update

export BACKEND_BUCKET     ?= terraform.agilestacks.com
export BACKEND_REGION     ?= us-east-1

export terraform          ?= terraform

deploy: init import plan apply

init:
	@mkdir -p .terraform/$(DOMAIN_NAME)
	@rm -rf .terraform/$(DOMAIN_NAME)/*
	$(terraform) init -get=true $(TF_OPTS) -force-copy \
		-backend=true -input=false \
		-backend-config="bucket=$(BACKEND_BUCKET)" \
		-backend-config="region=$(BACKEND_REGION)" \
		-backend-config="key=$(DOMAIN_NAME)/$(COMPONENT_NAME)/$(TF_VAR_name)/terraform.tfstate" \
		-backend-config="profile=$(AWS_PROFILE)" \
		. .terraform/$(DOMAIN_NAME)
.PHONY: init

get:
	cd .terraform/$(DOMAIN_NAME) && \
		$(terraform) get $(TF_UPDATE)
.PHONY: get

plan:
	cd .terraform/$(DOMAIN_NAME) && \
		$(terraform) plan $(TF_OPTS) -refresh=true -module-depth=-1 -out=terraform.tfplan
.PHONY: plan

apply:
	cd .terraform/$(DOMAIN_NAME) && \
		$(terraform) apply $(TF_OPTS) -Xshadow=false terraform.tfplan
.PHONY: apply

undeploy: init
	cd .terraform/$(DOMAIN_NAME) && \
		$(terraform) plan $(TF_OPTS) -destroy -refresh=true -module-depth=-1 -out=terraform.tfplan
	$(MAKE) apply
.PHONY: undeploy

import:
	-cd .terraform/$(DOMAIN_NAME) && \
		$(terraform) import $(TF_OPTS) module.ecr.aws_ecr_repository.main $(TF_VAR_name) \
		2>/dev/null
.PHONY: import
