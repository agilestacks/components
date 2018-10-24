.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= efs
DOMAIN_NAME    ?= dev.stacks.delivery
STATE_BUCKET   ?= terraform.agilestacks.com
STATE_REGION   ?= us-east-1

export AWS_DEFAULT_REGION ?= us-east-2
export TF_LOG             ?= info
export TF_LOG_PATH        ?= .terraform/$(DOMAIN_NAME).log
export TF_OPTS            ?= -no-color
export TF_UPDATE          ?= -update
export TF_DATA_DIR        := .terraform

export TF_VAR_name             := $(COMPONENT_NAME)
export TF_VAR_performance_mode ?= generalPurpose
export TF_VAR_subnet_id        ?=
export TF_VAR_sgs              ?=

terraform ?= terraform-v0.11
TFPLAN ?= .terraform/$(COMPONENT_NAME).tfplan

deploy: init plan apply output

$(TF_DATA_DIR):
	@mkdir -p "$@"

init: $(TF_DATA_DIR)
	$(terraform) init -get=true $(TF_CMD_OPTS) -reconfigure -force-copy  \
		-backend=true -input=false \
		-backend-config="bucket=$(STATE_BUCKET)" \
		-backend-config="region=$(STATE_REGION)" \
		-backend-config="key=$(DOMAIN_NAME)/efs/$(COMPONENT_NAME)/terraform.tfstate" \
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
	$(MAKE) plan TF_OPTS="-destroy -no-color"
	$(MAKE) apply
.PHONY: undeploy

output:
	$(terraform) output $(TF_OPTS) -json
.PHONY: output
