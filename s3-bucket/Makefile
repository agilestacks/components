.DEFAULT_GOAL := deploy

export AWS_DEFAULT_REGION ?= us-east-2

COMPONENT_NAME ?= s3
DOMAIN_NAME    ?= dev.kubernetes.delivery
STATE_BUCKET   ?= terraform.agilestacks.com
STATE_REGION   ?= us-east-1

export TF_LOG             ?= debug
export TF_LOG_PATH        ?= .terraform/$(DOMAIN_NAME).log
export TF_DATA_DIR        ?= .terraform
export TF_VAR_name        := $(COMPONENT_NAME)

terraform    ?= terraform-v0.11
CLI_ARGS  ?= -no-color -input=false

deploy: init plan
	$(MAKE) apply || \
	$(MAKE) import plan apply
.PHONY: deploy

$(TF_DATA_DIR):
	@ mkdir -p $@

init: $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(CLI_ARGS) \
        -backend=true -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(DOMAIN_NAME)/s3-bucket/$(COMPONENT_NAME)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"
.PHONY: init

plan:
	$(terraform) plan $(CLI_ARGS) -refresh=true -module-depth=-1 -out=.terraform/terraform.tfplan
.PHONY: plan

refresh:
	$(terraform) refresh $(CLI_ARGS)
.PHONY: refresh

apply:
	$(terraform) apply $(CLI_ARGS)  -auto-approve .terraform/terraform.tfplan
.PHONY: apply

output:
	@ $(terraform) output $(CLI_ARGS)
.PHONY: output

clean:
	rm -rf .terraform
.PHONY: clean

undeploy: init
	$(MAKE) plan CLI_ARGS="-destroy $(CLI_ARGS)"
	$(MAKE) apply
.PHONY: undeploy

import:
	- $(terraform) import $(CLI_ARGS) module.s3.aws_s3_bucket.main $(DOMAIN_NAME)
.PHONY: import
