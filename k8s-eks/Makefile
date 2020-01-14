.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= k8s-eks
DOMAIN_NAME    ?= eks.dev.superhub.io
NAME           := $(shell echo $(DOMAIN_NAME) | cut -d. -f1)
BASE_DOMAIN    := $(shell echo $(DOMAIN_NAME) | cut -d. -f2-)

STATE_BUCKET ?= terraform.agilestacks.com
STATE_REGION ?= us-east-1

SERVICE_ACCOUNT ?= asi

export AWS_DEFAULT_REGION ?= us-east-2

export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(DOMAIN_NAME)-$(COMPONENT_NAME)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log

export TF_VAR_name         := $(NAME)
export TF_VAR_base_domain  := $(BASE_DOMAIN)
export TF_VAR_api_endpoint ?= BEEF.yl4.us-east-2.eks.amazonaws.com

kubectl     ?= kubectl --context=$(DOMAIN_NAME)
terraform   ?= terraform-v0.11
TF_CLI_ARGS ?= -no-color -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan

deploy: init plan apply createsa storage token output

$(TF_DATA_DIR):
	@rm -rf $@ && mkdir -p $@

init: $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(DOMAIN_NAME)/k8s-eks/$(COMPONENT_NAME)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"

plan: vars
	$(terraform) plan -var vpc_id=$(VPC_ID) $(TF_CLI_ARGS) -refresh=true -module-depth=-1 -out=$(TFPLAN)

refresh: vars
	$(terraform) refresh $(TF_CLI_ARGS)

apply: vars
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)

vpc:
	@./vpc.sh | tee $(DOMAIN_NAME).log
	@grep -E '^vpc =' $(DOMAIN_NAME).log >/dev/null # make sure `tee` didn't mask an error
.PHONY: vpc

vars: vpc
	$(eval export AWS_DEFAULT_REGION := $(shell grep -E '^region =' $(DOMAIN_NAME).log | awk '{print $$3}'))
	$(eval VPC_ID := $(shell grep -E '^vpc =' $(DOMAIN_NAME).log | awk '{print $$3}'))
.PHONY: vars

createsa:
	$(kubectl) -n default get serviceaccount $(SERVICE_ACCOUNT) || \
		($(kubectl) -n default create serviceaccount $(SERVICE_ACCOUNT) && sleep 17)
	$(kubectl) get clusterrolebinding $(SERVICE_ACCOUNT)-cluster-admin-binding || \
		($(kubectl) create clusterrolebinding $(SERVICE_ACCOUNT)-cluster-admin-binding \
			--clusterrole=cluster-admin --serviceaccount=default:$(SERVICE_ACCOUNT) && sleep 7)
.PHONY: createsa

storage:
	$(kubectl) apply -f storage-class.yaml
.PHONY: storage

token:
	$(eval SECRET:=$(shell $(kubectl) -n default get serviceaccount $(SERVICE_ACCOUNT) -o json | \
		jq -r '.secrets[] | select(.name | contains("token")).name'))
	$(eval TOKEN:=$(shell $(kubectl) -n default get secret $(SECRET) -o json | \
		jq -r '.data.token'))
.PHONY: token

output: vpc
	@cat $(DOMAIN_NAME).log
	@echo
	@echo Outputs:
	@echo dns_name = $(NAME)
	@echo dns_base_domain = $(BASE_DOMAIN)
	@echo token = $(TOKEN) | $(HUB) util otp
	@echo

undeploy: init destroy apply

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

-include ../Mk/phonies
