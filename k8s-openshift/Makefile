.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= k8s-metal
DOMAIN_NAME    ?= metal.kubernetes.delivery
NAME           := $(shell echo $(DOMAIN_NAME) | cut -d. -f1)
BASE_DOMAIN    := $(shell echo $(DOMAIN_NAME) | cut -d. -f2-)
API_ENDPOINT   ?=
API_FQDN     := $(shell echo $(API_ENDPOINT) | cut -d: -f1)
API_PORT       := $(shell echo $(API_ENDPOINT) | cut -d: -f2)
$(if $(API_PORT),,API_PORT:=443)

STATE_BUCKET   ?= terraform.agilestacks.com
STATE_REGION   ?= us-east-1

export AWS_DEFAULT_REGION ?= us-east-2

export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(DOMAIN_NAME)-$(COMPONENT_NAME)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log

export TF_VAR_name        := $(NAME)
export TF_VAR_base_domain := $(BASE_DOMAIN)
export TF_VAR_api_fqdn      := $(API_FQDN)

oc ?= oc --context=$(DOMAIN_NAME)
kubectl     ?= kubectl --context=$(DOMAIN_NAME)
terraform   ?= terraform-v0.11
TF_CLI_ARGS ?= -no-color -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan

deploy: add-scc init vars plan apply output
$(TF_DATA_DIR):
	@rm -rf $@ && mkdir -p $@

add-scc:
	-$(oc) create -f agilestacks-scc.yaml

drop-scc:
	-$(oc) delete -f agilestacks-scc.yaml			

init: $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(DOMAIN_NAME)/k8s-openshift/$(COMPONENT_NAME)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"

plan:
	$(terraform) plan -var vpc_id=$(VPC_ID) $(TF_CLI_ARGS) -refresh=true -module-depth=-1 -out=$(TFPLAN)
.PHONY: plan	

refresh: 
	$(terraform) refresh $(TF_CLI_ARGS)
.PHONY: refresh	

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)
.PHONY: apply	

vpc:
	@./vpc.sh | tee $(DOMAIN_NAME).log
	@grep -E '^vpc =' $(DOMAIN_NAME).log >/dev/null
.PHONY: vpc

vars: vpc
	$(eval export AWS_DEFAULT_REGION := $(shell grep -E '^region =' $(DOMAIN_NAME).log | awk '{print $$3}'))
	$(eval VPC_ID := $(shell grep -E '^vpc =' $(DOMAIN_NAME).log | awk '{print $$3}'))
.PHONY: vars

output:
	@cat $(DOMAIN_NAME).log
	@echo
	@echo Outputs:
	@echo
	@echo dns_name = $(NAME)
	@echo dns_base_domain = $(BASE_DOMAIN)
	@echo
.PHONY: output	

undeploy: init vars destroy apply drop-scc

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

-include ../Mk/phonies
