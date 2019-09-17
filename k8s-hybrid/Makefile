.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= k8s-hybrid
DOMAIN_NAME    ?= cluster1.hybrid.dev.superhub.io
NAME           := $(shell echo $(DOMAIN_NAME) | cut -d. -f1)
BASE_DOMAIN    := $(shell echo $(DOMAIN_NAME) | cut -d. -f2-)
INGRESS_STATIC_HOST   ?= $(error you forgot to set variable INGRESS_STATIC_HOST)
API_HOST       := $(shell echo $(API_ENDPOINT) | cut -d: -f1)
API_PORT       := $(shell echo $(API_ENDPOINT) | cut -d: -f2)
$(if $(API_PORT),,API_PORT:=6443)

STATE_BUCKET   ?= terraform.agilestacks.com
STATE_REGION   ?= us-east-1

export AWS_DEFAULT_REGION ?= us-east-2

export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(DOMAIN_NAME)-$(COMPONENT_NAME)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log

export TF_VAR_name        := $(NAME)
export TF_VAR_base_domain := $(BASE_DOMAIN)
export TF_VAR_api_host    := $(INGRESS_STATIC_HOST)

TF_CLI_ARGS ?= -no-color -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan

terraform ?= terraform-v0.11
kubectl   ?= kubectl --kubeconfig=./kubeconfig --insecure-skip-tls-verify=true

deploy: init plan apply storage output

$(TF_DATA_DIR):
	@rm -rf $@ && mkdir -p $@

init: $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(DOMAIN_NAME)/k8s-hybrid/$(COMPONENT_NAME)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"

plan:
	$(terraform) plan $(TF_CLI_ARGS) -refresh=true -module-depth=-1 -out=$(TFPLAN)

refresh:
	$(terraform) refresh $(TF_CLI_ARGS)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)
	@echo

storage:
	$(kubectl) apply -f storage-class.yaml
.PHONY: storage

output:
	@echo
	@echo Outputs:
	@echo dns_name = $(NAME)
	@echo dns_base_domain = $(BASE_DOMAIN)
# if endpoint is not an IP then output it as is, else output api.domain:port
	@echo api_endpoint = api.$(DOMAIN_NAME):$(API_PORT)
	@echo

undeploy: init destroy apply

destroy: TF_OPTS=-destroy
destroy: plan

-include ../Mk/phonies
