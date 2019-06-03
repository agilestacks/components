.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= gcs-bucket
DOMAIN_NAME    ?= test.gcp.superhub.io

STATE_BUCKET ?= gcp-superhub-io
STATE_REGION ?= us-central1

export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(DOMAIN_NAME)-$(COMPONENT_NAME)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log

export TF_VAR_name := $(COMPONENT_NAME)

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
		-backend-config="prefix=$(DOMAIN_NAME)/gcs-bucket/$(COMPONENT_NAME)"

plan:
	$(terraform) plan $(TF_CLI_ARGS) -refresh=true -module-depth=-1 -out=$(TFPLAN)

refresh:
	$(terraform) refresh $(TF_CLI_ARGS)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)

output:
	@$(terraform) output -no-color

undeploy: init import destroy apply

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

import:
	-$(terraform) import $(TF_CLI_ARGS) google_storage_bucket.main $$(echo $(TF_VAR_name) | sed -e 's/\./-/g')

clean:
	rm -rf .terraform

-include ../Mk/phonies
