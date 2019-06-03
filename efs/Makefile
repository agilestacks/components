.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= efs
DOMAIN_NAME    ?= dev.stacks.delivery

STATE_BUCKET ?= terraform.agilestacks.com
STATE_REGION ?= us-east-1

export AWS_DEFAULT_REGION ?= us-east-2

export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(DOMAIN_NAME)-$(COMPONENT_NAME)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log

export TF_VAR_name      := $(COMPONENT_NAME)
export TF_VAR_subnet_id ?=
export TF_VAR_vpc_id    ?=
ifeq (openshift,$(KUBE_FLAVOR))
# reset security group list to create new security group
export TF_VAR_sgs       :=
else
export TF_VAR_sgs       ?=
endif
export TF_VAR_performance_mode       ?= generalPurpose
export TF_VAR_provisioned_throughput ?= 0

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
        -backend-config="key=$(DOMAIN_NAME)/efs/$(COMPONENT_NAME)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"

plan:
	$(terraform) plan $(TF_CLI_ARGS) -refresh=true -module-depth=-1 -out=$(TFPLAN)

refresh:
	$(terraform) refresh $(TF_CLI_ARGS)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)

output:
	@$(terraform) output -no-color

undeploy: init destroy apply

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

clean:
	rm -rf .terraform

-include ../Mk/phonies
