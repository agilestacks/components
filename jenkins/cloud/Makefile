.DEFAULT_GOAL := deploy

export TF_VAR_name        ?= dev
export AWS_PROFILE        ?= default
export AWS_DEFAULT_REGION ?= us-east-2
export TF_VAR_base_domain ?= stacks.delivery
export TF_LOG             ?= debug
export TF_LOG_PATH        ?= $(shell pwd)/.terraform/$(TF_VAR_name).$(TF_VAR_base_domain).log
export TF_OPTS            ?= -no-color
export TF_UPDATE          ?= -update

COMPONENT_NAME ?= jenkins
STATE_BUCKET   ?= terraform.agilestacks.com
STATE_REGION   ?= us-east-1

terraform      ?= terraform

deploy: init import plan apply

init:
	@mkdir -p .terraform/$(TF_VAR_name).$(TF_VAR_base_domain)
	@rm -rf .terraform/$(TF_VAR_name).$(TF_VAR_base_domain)/*
	$(terraform) init -get=true $(TF_CMD_OPTS) -force-copy  \
		-backend=true -input=false \
		-backend-config="bucket=$(STATE_BUCKET)" \
		-backend-config="region=$(STATE_REGION)" \
		-backend-config="key=$(TF_VAR_name).$(TF_VAR_base_domain)/automation-hub/$(COMPONENT_NAME)/terraform.tfstate" \
		-backend-config="profile=$(AWS_PROFILE)" \
		. .terraform/$(TF_VAR_name).$(TF_VAR_base_domain)
.PHONY: init

get:
	@cd .terraform/$(TF_VAR_name).$(TF_VAR_base_domain) && \
		$(terraform) get $(TF_UPDATE)
.PHONY: get

plan:
	@cd .terraform/$(TF_VAR_name).$(TF_VAR_base_domain) && \
	$(terraform) plan $(TF_OPTS) -refresh=true -module-depth=-1 -out=terraform.tfplan
.PHONY: plan

apply:
	@cd .terraform/$(TF_VAR_name).$(TF_VAR_base_domain) && \
	$(terraform) apply $(TF_OPTS) -Xshadow=false terraform.tfplan
.PHONY: apply

undeploy: init
	@cd .terraform/$(TF_VAR_name).$(TF_VAR_base_domain) && \
	$(terraform) plan $(TF_OPTS) -destroy -refresh=true -module-depth=-1 -out=terraform.tfplan
	$(terraform) plan $(TF_OPTS) -destroy -refresh=true -module-depth=-1 -out=terraform.tfplan
	$(MAKE) apply
.PHONY: undeploy

import:
	-cd .terraform/$(TF_VAR_name).$(TF_VAR_base_domain) && \
	$(terraform) import $(TF_OPTS) aws_iam_role.jenkins $(TF_VAR_name).$(TF_VAR_base_domain)-jenkins_iam_role && \
	$(terraform) import $(TF_OPTS) aws_iam_role_policy.jenkins $(TF_VAR_name).$(TF_VAR_base_domain)-jenkins_iam_role:jenkins_iam_role_policy \
		2>/dev/null
.PHONY: import
