.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= s3
DOMAIN_NAME    ?= dev.kubernetes.delivery

STATE_BUCKET ?= terraform.agilestacks.com
STATE_REGION ?= us-east-1

export AWS_DEFAULT_REGION ?= us-east-2

export TF_DATA_DIR ?= .terraform/$(DOMAIN_NAME)-$(COMPONENT_NAME)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log

export TF_VAR_name := $(COMPONENT_NAME)

terraform   ?= terraform-v0.12
TF_CLI_ARGS ?= -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan

RECLAIM     ?= delete

deploy: init plan
	$(MAKE) apply || \
	$(MAKE) import plan apply

$(TF_DATA_DIR):
	@rm -rf $@ && mkdir -p $@

# Terraform doesn't allow interpolation for lifecycle
bucket.tf:
	cp -f bucket-$(RECLAIM).tf.ignore $@
.PHONY: bucket.tf

init: $(TF_DATA_DIR) bucket.tf
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(DOMAIN_NAME)/s3-bucket/$(COMPONENT_NAME)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"

plan:
	$(terraform) plan $(TF_CLI_ARGS) -refresh=true -out=$(TFPLAN)

refresh:
	$(terraform) refresh $(TF_CLI_ARGS)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)
	@echo

output:
	@$(terraform) output -no-color

# see https://github.com/hashicorp/terraform/issues/17599
undeploy: init
ifeq ($(RECLAIM),retain)
	- $(MAKE) TF_CLI_ARGS="$(TF_CLI_ARGS) -destroy" plan \
	&& $(MAKE) apply TF_CLI_ARGS="$(TF_CLI_ARGS)"
else
	$(MAKE) TF_CLI_ARGS="$(TF_CLI_ARGS) -destroy" plan \
	&& $(MAKE) apply TF_CLI_ARGS="$(TF_CLI_ARGS)"
endif

import:
	-$(terraform) import $(TF_CLI_ARGS) aws_s3_bucket.main $(TF_VAR_name)

clean:
	rm -rf .terraform bucket.tf

-include ../Mk/phonies
