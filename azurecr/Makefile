.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= azurecr
DOMAIN_NAME    ?= test.dev.superhub.io

STATE_BUCKET    ?= azuredevsuperhubio
STATE_REGION    ?= eastus
STATE_CONTAINER ?= agilestacks

export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(DOMAIN_NAME)-$(COMPONENT_NAME)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log

export TF_VAR_azure_location ?= eastus
export TF_VAR_registry_name  := $(shell echo $(COMPONENT_NAME) | sed -E -e 's/[^[:alnum:]]+//g' | cut -c 1-50)

export TF_VAR_azure_subscription_id     ?= 00000000-0000-0000-0000-000000000000
export TF_VAR_azure_resource_group_name ?= superhub-$(STATE_REGION)

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
		-backend-config="storage_account_name=$(STATE_BUCKET)" \
		-backend-config="container_name=$(STATE_CONTAINER)" \
		-backend-config="resource_group_name=$(TF_VAR_azure_resource_group_name)" \
		-backend-config="key=$(DOMAIN_NAME)/azurecr/$(TF_VAR_registry_name)/terraform.tfstate"

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
	-$(terraform) import $(TF_OPTS) azurerm_container_registry.main \
		/subscriptions/$(TF_VAR_azure_subscription_id)/resourceGroups/$(TF_VAR_azure_resource_group_name)/providers/Microsoft.ContainerRegistry/registries/$(TF_VAR_registry_name)

clean:
	rm -rf .terraform

-include ../Mk/phonies
