.DEFAULT_GOAL := deploy

export DOMAIN_NAME        ?= dev.kubernetes.delivery
export ADDITIONAL_NAMES   ?= 
export ZONE_DOMAIN        ?= $(DOMAIN_NAME)
export AWS_PROFILE        ?= default
export AWS_DEFAULT_REGION ?= us-east-1
export TF_LOG             ?= info
export TF_LOG_PATH        ?= $(shell pwd)/.terraform/$(DOMAIN_NAME)/terraform.log
export ACM_DELETE_CERTIFICATE ?= false

TF_OPTS        ?= -no-color
TF_UPDATE      ?= -update
BACKEND_BUCKET ?= terraform.agilestacks.com
BACKEND_REGION ?= us-east-1
python         := . .venv/bin/activate && python
terraform      := terraform

deploy: venv install cert init plan apply output

# deploy: init plan

venv:
	virtualenv .venv
	. .venv/bin/activate

init:
	@mkdir -p $(shell pwd)/.terraform/$(DOMAIN_NAME)
	@rm -rf .terraform/$(DOMAIN_NAME)/*
	yes yes | $(terraform) init -get=true $(TF_CMD_OPTS) -force-copy  \
		-backend=true -input=false \
		-backend-config="bucket=$(BACKEND_BUCKET)" \
 		-backend-config="region=$(BACKEND_REGION)" \
 		-backend-config="key=acm/$(DOMAIN_NAME)/terraform.tfstate" \
 		-backend-config="profile=$(AWS_PROFILE)" \
 		. .terraform/$(DOMAIN_NAME)

get:
	cd .terraform/$(DOMAIN_NAME) && \
		$(terraform) get $(TF_UPDATE)
.PHONY: get

plan:
	cd .terraform/$(DOMAIN_NAME) && \
	$(terraform) plan $(TF_OPTS) -refresh=true -module-depth=-1 -out=terraform.tfplan
.PHONY: plan

apply:
	cd .terraform/$(DOMAIN_NAME) && \
	$(terraform) apply $(TF_OPTS) -Xshadow=false terraform.tfplan
.PHONY: apply

undeploy: init
	cd .terraform/$(DOMAIN_NAME) && \
	$(terraform) plan $(TF_OPTS) -destroy -refresh=true -module-depth=-1 -out=terraform.tfplan
	$(MAKE) apply
ifeq ($(ACM_DELETE_CERTIFICATE),true)
	$(python) main.py delete $(DOMAIN_NAME)
endif
	rm -f generated.tf
.PHONY: deploy


install: venv
	. .venv/bin/activate && pip install -r requirements.txt --upgrade

cert:
	$(python) main.py request $(DOMAIN_NAME) $(ADDITIONAL_NAMES) 
	$(python) main.py gen $(DOMAIN_NAME) \
		--standalone \
		--save-to generated.tf \
		--zone $(ZONE_DOMAIN)

test:
	python test_main.py
.PHONY: test

output:
	@echo Outputs:
	@echo certificate_arn=$(shell $(python) main.py arn $(DOMAIN_NAME))
.PHONY: output

clean:
	rm -rf .venv
	rm -rf cd .terraform/$(DOMAIN_NAME)
	rm -f generated.tf
