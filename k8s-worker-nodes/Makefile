.DEFAULT_GOAL := deploy

STATE_BUCKET ?= terraform.agilestacks.com
STATE_REGION ?= us-east-1

export AWS_DEFAULT_REGION ?= us-east-2

export DOMAIN_NAME      ?= default
export TF_VAR_pool_name ?= gpu1
export TF_VAR_s3_bucket := files.$(DOMAIN_NAME)

export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(TF_VAR_name)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log

kubectl     ?= kubectl --context="$(DOMAIN_NAME)" --namespace=kube-system
terraform   ?= terraform-v0.11
TF_CLI_ARGS ?= -no-color -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan

export TF_VAR_subnet_ids := $(shell echo -n '$(SUBNET_IDS)' | tr ',' ' ' | xargs | jq -cRM 'split(" ")') 
export TF_VAR_sg_ids     := $(shell echo -n '$(SG_IDS)' | tr ',' ' ' | xargs | jq -cRM 'split(" ")') 


deploy: init import plan apply kubernetes

$(TF_DATA_DIR):
	@rm -rf $@ && mkdir -p $@

init: $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(DOMAIN_NAME)/k8s-worker-nodes/$(TF_VAR_name)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"

plan:
	$(terraform) plan -var cluster_tag=$${TF_VAR_domain/./-} $(TF_CLI_ARGS) -refresh=true -module-depth=-1 -out=$(TFPLAN)

refresh:
	$(terraform) refresh $(TF_CLI_ARGS)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)

# we should make it a part of stack-k8s-aws? then what about eks?
kubernetes:
	$(kubectl) apply -f nvidia-gpu-device-plugin.yml

output:
	@$(terraform) output -no-color

undeploy: init destroy apply

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

import:
	$(eval worker=$(shell echo worker-$(TF_VAR_name) | cut -c 1-63))
	-$(terraform) import $(TF_OPTS) aws_autoscaling_group.workers $(worker)

-include ../Mk/phonies
