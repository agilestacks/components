.DEFAULT_GOAL := deploy

STATE_BUCKET ?= gcp-superhub-io
STATE_REGION ?= us-central1
COMPONENT_NAME := gke-worker-nodes

LOCATION := $(REGION)
ifneq (,$(ZONE))
	LOCATION=$(ZONE)
endif

export TF_VAR_domain    ?= dev.kubernetes.delivery
export TF_VAR_pool_name ?= gpu1
export TF_VAR_location ?= $(LOCATION)

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
	$(terraform) init -get=true $(TF_CLI_ARGS) -reconfigure -force-copy \
		-backend-config="bucket=$(STATE_BUCKET)" \
		-backend-config="prefix=$(DOMAIN_NAME)/$(COMPONENT_NAME)/$(TF_VAR_pool_name)"

plan:
	$(terraform) plan $(TF_CLI_ARGS) \
		-refresh=true -module-depth=-1 -out=$(TFPLAN)

refresh:
	$(terraform) refresh $(TF_CLI_ARGS)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)

output:
	@$(terraform) output -no-color

undeploy: init destroy apply

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

-include ../Mk/phonies
