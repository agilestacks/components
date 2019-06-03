.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= postgresql-rds
DOMAIN_NAME    ?= test.dev.superhub.io

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
TFSTATE     := $(TF_DATA_DIR)/terraform.tfstate

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

# removing TF_DATA_DIR to prevent Terraform from destroying previous db snapshot recorded into state
# setting -state explicitly due to Terraform putting .tfstate file in cwd despite TF_DATA_DIR
backup:
	cd backup && \
		rm -rf $(TF_DATA_DIR) && \
		mkdir -p $(TF_DATA_DIR) && \
		$(terraform) init -get=true -force-copy -reconfigure $(TF_CLI_ARGS) && \
		$(terraform) plan $(TF_CLI_ARGS) -refresh=true -module-depth=-1 -state=$(TFSTATE) -out=$(TFPLAN) && \
		$(terraform) apply $(TF_CLI_ARGS) -auto-approve -state-out=$(TFSTATE) $(TFPLAN)
	@echo
	@echo Outputs:
	@echo kind = postgresql-rds
	@echo

undeploy: init import destroy apply

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

import:
	-$(terraform) import $(TF_CLI_ARGS) aws_db_instance.postgresql $$(echo $(TF_VAR_rds_name) | sed -E -e 's/[^[:alnum:]]+/-/g' | cut -c 1-63)

clean:
	rm -rf .terraform

-include ../Mk/phonies
