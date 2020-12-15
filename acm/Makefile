.DEFAULT_GOAL := deploy

COMPONENT_NAME         ?= acm
DOMAIN_NAME            ?= test.dev.superhub.io
ADDITIONAL_NAMES       ?=
ACM_DELETE_CERTIFICATE ?= false
TIMEOUT                ?= 1200

STATE_BUCKET ?= terraform.agilestacks.com
STATE_REGION ?= us-east-1

export AWS_DEFAULT_REGION ?= us-east-2

export TF_DATA_DIR ?= .terraform/$(DOMAIN_NAME)-$(COMPONENT_NAME)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log

terraform   ?= terraform
TF_CLI_ARGS ?= -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan

TF_GENERATED_DIR := $(DOMAIN_NAME)-$(COMPONENT_NAME)

VENV_DIR := .venv
python   := test -f $(VENV_DIR)/bin/activate && . $(VENV_DIR)/bin/activate; python3
pip      := test -f $(VENV_DIR)/bin/activate && . $(VENV_DIR)/bin/activate; pip

deploy: install cert init plan apply wait output

$(TF_DATA_DIR):
	@rm -rf $@ && mkdir -p $@

init: $(TF_DATA_DIR) $(TF_GENERATED_DIR)/generated.tf
	$(terraform) init -get=true -reconfigure -force-copy $(TF_CLI_ARGS) \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(DOMAIN_NAME)/acm/$(COMPONENT_NAME)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)" \
        $(TF_GENERATED_DIR)

plan:
	$(terraform) plan $(TF_CLI_ARGS) -out=$(TFPLAN) $(TF_GENERATED_DIR)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)

undeploy: install init destroy apply
ifeq ($(ACM_DELETE_CERTIFICATE),true)
undeploy: delete
endif

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

delete:
	$(python) main.py delete $(DOMAIN_NAME)

$(VENV_DIR):
	python3 -m venv $(VENV_DIR)

install: $(VENV_DIR)
	$(pip) install -r requirements.txt --upgrade --no-cache

cert: install
	$(python) main.py request $(DOMAIN_NAME) $(ADDITIONAL_NAMES)
.PHONY: cert

$(TF_GENERATED_DIR)/generated.tf:
	@mkdir -p $(TF_GENERATED_DIR)
	$(python) main.py gen $(DOMAIN_NAME) \
		--standalone \
		--save-to $(TF_GENERATED_DIR)/generated.tf
.PHONY: $(TF_GENERATED_DIR)/generated.tf

wait: install
	$(python) main.py wait $(DOMAIN_NAME) --timeout $(TIMEOUT)

output: CERTIFICATE_ARN=$(shell $(python) main.py arn $(DOMAIN_NAME))
output:
	@echo
	@echo Outputs:
	@echo certificate_arn=$(CERTIFICATE_ARN)
	@echo

clean:
	rm -rf .venv .terraform

-include ../Mk/phonies
