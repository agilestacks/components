.DEFAULT_GOAL := deploy

STATE_BUCKET ?= terraform.agilestacks.com
STATE_REGION ?= us-east-1

export AWS_DEFAULT_REGION ?= us-east-2

export TF_VAR_domain    ?= dev.kubernetes.delivery
export TF_VAR_pool_name ?= gpu1

export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(TF_VAR_domain)-$(TF_VAR_pool_name)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log

terraform   ?= terraform-v0.11
TF_CLI_ARGS ?= -no-color -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan

deploy: init plan apply

$(TF_DATA_DIR):
	@rm -rf $@ && mkdir -p $@

init: $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(TF_VAR_domain)/eks-worker-nodes/$(TF_VAR_pool_name)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"

plan:
	$(terraform) plan $(TF_CLI_ARGS) -refresh=true -module-depth=-1 -out=$(TFPLAN)

refresh:
	$(terraform) refresh $(TF_CLI_ARGS)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)

output:
	@$(terraform) output $(TF_CLI_ARGS)

undeploy: init destroy apply

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

include ../Mk/phonies
