.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= k8s-metal
DOMAIN_NAME    ?= metal.kubernetes.delivery
NAME           := $(shell echo $(DOMAIN_NAME) | cut -d. -f1)
BASE_DOMAIN    := $(shell echo $(DOMAIN_NAME) | cut -d. -f2-)
API_ENDPOINT   ?= 10.0.10.20:6443
API_IP         := $(shell echo $(API_ENDPOINT) | cut -d: -f1)
API_PORT       := $(shell echo $(API_ENDPOINT) | cut -d: -f2)
$(if $(API_PORT),,API_PORT:=443)
STATE_BUCKET   ?= terraform.agilestacks.com
STATE_REGION   ?= us-east-1

export AWS_PROFILE        ?= default
export AWS_DEFAULT_REGION ?= us-east-1
export TF_LOG             ?= warn
export TF_LOG_PATH        ?= .terraform/$(DOMAIN_NAME).log
export TF_OPTS            ?= -no-color
export TF_UPDATE          ?= -update

export TF_VAR_name        := $(NAME)
export TF_VAR_base_domain := $(BASE_DOMAIN)
export TF_VAR_bucket      ?= files.$(DOMAIN_NAME)
export TF_VAR_api_ip      := $(API_IP)

terraform ?= terraform-v0.11
TFPLAN ?= .terraform/$(COMPONENT_NAME).tfplan

deploy: init plan apply output

init:
	@mkdir -p .terraform
	$(terraform) init -get=true $(TF_CMD_OPTS) -reconfigure -force-copy  \
		-backend=true -input=false \
		-backend-config="bucket=$(STATE_BUCKET)" \
		-backend-config="region=$(STATE_REGION)" \
		-backend-config="key=$(DOMAIN_NAME)/k8s-metal/$(COMPONENT_NAME)/terraform.tfstate" \
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

output:
	@echo
	@echo Outputs:
	@echo dns_name = $(NAME)
	@echo dns_base_domain = $(BASE_DOMAIN)
	@echo api_endpoint = api.$(DOMAIN_NAME):$(API_PORT)
	@echo
.PHONY: output

undeploy: init destroy apply

destroy: TF_OPTS=-destroy
destroy: plan
