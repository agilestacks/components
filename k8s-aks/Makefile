.DEFAULT_GOAL := deploy

DOMAIN_NAME    ?= superaks.azure.superhub.io
COMPONENT_NAME ?= k8s-aks

NAME           := $(shell echo $(DOMAIN_NAME) | cut -d. -f1)
BASE_DOMAIN    := $(shell echo $(DOMAIN_NAME) | cut -d. -f2-)

STATE_BUCKET ?= azuresuperhubio
STATE_CONTAINER ?= agilestacks
CLOUD_RESOURCE_GROUP ?= SuperHub

export TF_VAR_client_id := $(AZURE_CLIENT_ID)
export TF_VAR_client_secret := $(AZURE_CLIENT_SECRET)

export TF_VAR_aks_resource_group_name ?= SuperHub
export TF_VAR_cloud_resource_group_name := $(CLOUD_RESOURCE_GROUP)
export TF_VAR_location ?= eastus
export TF_VAR_domain_name := $(DOMAIN_NAME)
export TF_VAR_cluster_name := $(CLUSTER_NAME)
export TF_VAR_name := $(NAME)
export TF_VAR_base_domain := $(BASE_DOMAIN)

export TF_LOG      ?=
export TF_DATA_DIR ?= .terraform/$(DOMAIN_NAME)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log
TF_CLI_ARGS := -no-color -input=false -lock=false
TFPLAN := $(TF_DATA_DIR)/$(DOMAIN_NAME).tfplan

terraform ?= terraform-v0.12
az ?= az
kubectl ?= kubectl

export ARM_CLIENT_ID ?= $(AZURE_CLIENT_ID)
export ARM_CLIENT_SECRET ?= $(AZURE_CLIENT_SECRET)
export ARM_SUBSCRIPTION_ID ?= $(AZURE_SUBSCRIPTION_ID)
export ARM_TENANT_ID ?= $(AZURE_TENANT_ID)

deploy: createsa init plan apply token output

init:
	@mkdir -p $(TF_DATA_DIR)
	$(terraform) init -get=true $(TF_CLI_ARGS) -reconfigure -force-copy \
		-backend-config="storage_account_name=$${STATE_BUCKET//./}" \
		-backend-config="container_name=$(STATE_CONTAINER)" \
		-backend-config="resource_group_name=$(CLOUD_RESOURCE_GROUP)" \
		-backend-config="key=$(DOMAIN_NAME)/$(COMPONENT_NAME)/terraform.tfstate"
.PHONY: init

plan:
	$(terraform) plan $(TF_CLI_ARGS) -refresh=true -out=$(TFPLAN)
.PHONY: plan

apply:
	$(terraform) apply $(TF_CLI_ARGS) -Xshadow=false $(TFPLAN)
.PHONY: apply

context:
	$(az) aks get-credentials --resource-group $(TF_VAR_aks_resource_group_name) --name $(TF_VAR_cluster_name)
.PHONY: context

check:
	$(eval EXISTING_DOMAIN:=$(shell $(kubectl) get stackinfo asi-metadata -o json | jq -r .spec.domainName))
	@if [ "$(EXISTING_DOMAIN)" != "" ] && [ "$(EXISTING_DOMAIN)" != "$(DOMAIN_NAME)" ]; then\
    echo "Error: This cluster has already been imported using domain name: $(EXISTING_DOMAIN)";\
		echo "Error: Change of the domain name is not supported. This deployment will fail...";\
		exit 1;\
  fi
.PHONY: check

createsa: context check
	$(kubectl) get -n default serviceaccount $(SERVICE_ACCOUNT) || \
		($(kubectl) create -n default serviceaccount $(SERVICE_ACCOUNT) && sleep 7)
	$(kubectl) get clusterrolebinding $(SERVICE_ACCOUNT)-cluster-admin-binding || \
		($(kubectl) create clusterrolebinding $(SERVICE_ACCOUNT)-cluster-admin-binding \
			--clusterrole=cluster-admin --serviceaccount=default:$(SERVICE_ACCOUNT) && sleep 7)
.PHONY: createsa

deletesa: context
	-$(kubectl) delete clusterrolebinding $(SERVICE_ACCOUNT)-cluster-admin-binding
	-$(kubectl) delete -n default serviceaccount $(SERVICE_ACCOUNT)
.PHONY: deletesa

token:
	$(eval SECRET:=$(shell $(kubectl) get serviceaccount $(SERVICE_ACCOUNT) -o json | \
		jq -r '.secrets[] | select(.name | contains("token")).name'))
	$(eval TOKEN:=$(shell $(kubectl) get secret $(SECRET) -o json | \
		jq -r '.data.token'))
.PHONY: token

output:
	@echo
	@echo Outputs:
	@echo dns_name = $(NAME)
	@echo dns_base_domain = $(BASE_DOMAIN)
	@echo token = $(TOKEN) | $(HUB) util otp
	@echo
.PHONY: output

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

undeploy: context check init destroy apply deletesa
