.DEFAULT_GOAL := deploy

export COMPONENT_NAME        ?= postgres-rds
export DOMAIN_NAME           ?= dev.stacks.delivery
export TF_VAR_rds_name       ?= postgresql
export AWS_PROFILE           ?= default
export AWS_DEFAULT_REGION    ?= us-east-2
export TF_LOG                ?= info
export TF_LOG_PATH           ?= .terraform/$(TF_VAR_rds_name).$(DOMAIN_NAME).log
export TF_OPTS               ?= -no-color
export TF_UPDATE             ?= -update

export terraform             ?= terraform

export STATE_BUCKET ?= terraform.agilestacks.com
export STATE_REGION ?= us-east-1

deploy: init plan apply

init:
	@mkdir -p .terraform/$(TF_VAR_rds_name).$(DOMAIN_NAME)
	@rm -rf .terraform/$(TF_VAR_rds_name).$(DOMAIN_NAME)/*
	yes yes | $(terraform) init -get=true $(TF_OPTS) -force-copy  \
		-backend=true -input=false \
		-backend-config="bucket=$(STATE_BUCKET)" \
		-backend-config="region=$(STATE_REGION)" \
		-backend-config="key=$(DOMAIN_NAME)/postgresql-rds/$(COMPONENT_NAME)/terraform.tfstate" \
		-backend-config="profile=$(AWS_PROFILE)" \
		. .terraform/$(TF_VAR_rds_name).$(DOMAIN_NAME)
.PHONY: init

get:
	cd .terraform/$(TF_VAR_rds_name).$(DOMAIN_NAME) && \
		$(terraform) get $(TF_UPDATE)
.PHONY: get

plan:
	cd .terraform/$(TF_VAR_rds_name).$(DOMAIN_NAME) && \
		$(terraform) plan $(TF_OPTS) -refresh=true -module-depth=-1 -out=terraform.tfplan
.PHONY: plan

apply:
	cd .terraform/$(TF_VAR_rds_name).$(DOMAIN_NAME) && \
		$(terraform) apply $(TF_OPTS) -Xshadow=false terraform.tfplan
.PHONY: apply

backup:
	cd backup && \
		mkdir -p .terraform && \
		$(terraform) init $(TF_OPTS) && \
		$(terraform) plan $(TF_OPTS) -refresh=true -module-depth=-1 \
			-state=.terraform/$(TF_VAR_rds_name).$(DOMAIN_NAME).tfstate \
			-out=.terraform/$(TF_VAR_rds_name).$(DOMAIN_NAME).tfplan && \
		$(terraform) apply $(TF_OPTS) -Xshadow=false \
			-state-out=.terraform/$(TF_VAR_rds_name).$(DOMAIN_NAME).tfstate \
			.terraform/$(TF_VAR_rds_name).$(DOMAIN_NAME).tfplan
	@echo
	@echo Outputs:
	@echo kind = postgresql-rds
	@echo
.PHONY: backup

undeploy: import
	cd .terraform/$(TF_VAR_rds_name).$(DOMAIN_NAME) && \
		$(terraform) plan $(TF_OPTS) -destroy -refresh=true -module-depth=-1 -out=terraform.tfplan
	$(MAKE) apply
.PHONY: undeploy

import: init
	-cd .terraform/$(TF_VAR_rds_name).$(DOMAIN_NAME) && \
		terraform import aws_db_instance.postgresql $(TF_VAR_rds_name)
.PHONY: import

