.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= k8s-eks
DOMAIN_NAME    ?= eks.kubernetes.delivery
NAME           := $(shell echo $(DOMAIN_NAME) | cut -d. -f1)
BASE_DOMAIN    := $(shell echo $(DOMAIN_NAME) | cut -d. -f2-)
STATE_BUCKET   ?= terraform.agilestacks.com
STATE_REGION   ?= us-east-1

export AWS_PROFILE        ?= default
export AWS_DEFAULT_REGION ?= us-east-1
export TF_LOG             ?= warn
export TF_LOG_PATH        ?= .terraform/$(DOMAIN_NAME).log
export TF_OPTS            ?= -no-color
export TF_UPDATE          ?= -update

export TF_VAR_name         := $(NAME)
export TF_VAR_base_domain  := $(BASE_DOMAIN)
export TF_VAR_bucket       ?= files.$(DOMAIN_NAME)
export TF_VAR_api_endpoint ?= BEEF.yl4.us-east-1.eks.amazonaws.com

terraform ?= terraform-v0.11
TFPLAN ?= .terraform/$(COMPONENT_NAME).tfplan

deploy: output init plan apply

init:
	@mkdir -p .terraform
	$(terraform) init -get=true $(TF_CMD_OPTS) -reconfigure -force-copy  \
		-backend=true -input=false \
		-backend-config="bucket=$(STATE_BUCKET)" \
		-backend-config="region=$(STATE_REGION)" \
		-backend-config="key=$(DOMAIN_NAME)/k8s-eks/$(COMPONENT_NAME)/terraform.tfstate" \
		-backend-config="profile=$(AWS_PROFILE)"
.PHONY: init

get:
	$(terraform) get $(TF_UPDATE)
.PHONY: get

plan:
	$(eval VPC_ID := $(shell grep -E '^vpc =' $(DOMAIN_NAME).log | awk '{print $$3}'))
	$(terraform) plan -var vpc_id=$(VPC) $(TF_OPTS) -refresh=true -module-depth=-1 -out=$(TFPLAN)
.PHONY: plan

apply:
	$(terraform) apply $(TF_OPTS) -Xshadow=false $(TFPLAN)
.PHONY: apply

output:
	@./vpc.sh | tee $(DOMAIN_NAME).log
	@grep -E '^vpc =' $(DOMAIN_NAME).log >/dev/null # make sure `tee` didn't mask an error
	@echo
	@echo Outputs:
	@echo dns_name = $(NAME)
	@echo dns_base_domain = $(BASE_DOMAIN)
	@echo
.PHONY: output

undeploy: init
	$(MAKE) plan TF_OPTS=-destroy
	$(MAKE) apply
.PHONY: undeploy
