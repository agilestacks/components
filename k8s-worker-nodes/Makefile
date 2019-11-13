.DEFAULT_GOAL := deploy

export AWS_DEFAULT_REGION      ?= us-east-2

terraform   ?= terraform-v0.11
jq := jq -cRM

export TF_VAR_name             ?= $(error undefined env var TF_VAR_name)
export TF_VAR_s3_bucket        ?= $(error undefined env var TF_VAR_s3_bucket)
export TF_VAR_s3_bucket_region ?= $(error undefined env var TF_VAR_s3_bucket_region)
export TF_VAR_domain_name      ?= $(error undefined env var TF_VAR_domain_name)
export TF_VAR_subnet_ids       := $(shell echo -n '$(sort $(SUBNET_ID) $(SUBNET_IDS))' | tr ',' ' ' | xargs | $(jq) 'split(" ")')
export TF_VAR_sg_ids           := $(shell echo -n '$(SG_IDS)' | tr ',' ' ' | xargs | $(jq) 'split(" ")')

export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(TF_VAR_name)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log

kubectl     ?= kubectl --context="$(TF_VAR_domain_name)"
TF_CLI_ARGS ?= -no-color -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan


deploy: init import plan
	# workaround famous ignition provider bug
	$(MAKE) apply || \
	$(MAKE) import plan apply
	$(MAKE) kubernetes/nvidia-gpu-device-plugin.yml

$(TF_DATA_DIR):
	@rm -rf $@ && mkdir -p $@

init: $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
        -backend-config="bucket=$(TF_VAR_s3_bucket)" \
        -backend-config="region=$(TF_VAR_s3_bucket_region)" \
        -backend-config="key=$(TF_VAR_domain_name)/k8s-worker-nodes/$(TF_VAR_name)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"

plan:
	$(terraform) plan -var cluster_tag=$${TF_VAR_domain_name/./-} $(TF_CLI_ARGS) -refresh=true -module-depth=-1 -out=$(TFPLAN)

refresh:
	$(terraform) refresh $(TF_CLI_ARGS)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)

# we should make it a part of stack-k8s-aws? then what about eks?
kubernetes/%:
	$(kubectl) apply  -n kube-system -f $@

output:
	@$(terraform) output -no-color

undeploy: init destroy apply

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

import:
	$(eval worker=$(shell echo worker-$(TF_VAR_name) | cut -c 1-63))
	-$(terraform) import $(TF_OPTS) aws_autoscaling_group.workers $(worker)

-include ../Mk/phonies

.PHONY: kubernetes/nvidia-gpu-device-plugin.yml
