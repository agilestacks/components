.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= postgresql-rds
DOMAIN_NAME    ?= dev.stacks.delivery

STATE_BUCKET ?= terraform.agilestacks.com
STATE_REGION ?= us-east-1

export AWS_DEFAULT_REGION ?= us-east-2

export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(DOMAIN_NAME)-$(COMPONENT_NAME)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log

export TF_VAR_rds_name ?= postgresql

terraform   ?= terraform-v0.11
TF_CLI_ARGS ?= -no-color -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan

deploy: init import plan apply

$(TF_DATA_DIR):
	@rm -rf $@ && mkdir -p $@

init: $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(DOMAIN_NAME)/postgresql-rds/$(COMPONENT_NAME)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"

plan:
	$(terraform) plan $(TF_CLI_ARGS) -refresh=true -module-depth=-1 -out=$(TFPLAN)

refresh:
	$(terraform) refresh $(TF_CLI_ARGS)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)

output:
	@$(terraform) output -no-color

backup:
	cd backup && \
		mkdir -p .terraform && \
		terraform-v0.9 init $(TF_OPTS) && \
		terraform-v0.9 plan $(TF_OPTS) -refresh=true -module-depth=-1 \
			-state=.terraform/$(TF_VAR_rds_name).$(DOMAIN_NAME).tfstate \
			-out=.terraform/$(TF_VAR_rds_name).$(DOMAIN_NAME).tfplan && \
		terraform-v0.9 apply $(TF_OPTS) -Xshadow=false \
			-state-out=.terraform/$(TF_VAR_rds_name).$(DOMAIN_NAME).tfstate \
			.terraform/$(TF_VAR_rds_name).$(DOMAIN_NAME).tfplan
	@echo
	@echo Outputs:
	@echo kind = postgresql-rds
	@echo

undeploy: init import destroy apply

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

import:
	-$(terraform) import $(TF_CLI_ARGS) aws_db_instance.postgresql $$(echo $(TF_VAR_rds_name) | sed -e 's/[^[:alnum:]-]/-/g')

clean:
	rm -rf .terraform

-include ../Mk/phonies
