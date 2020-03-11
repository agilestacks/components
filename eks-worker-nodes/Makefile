.DEFAULT_GOAL := deploy

STATE_BUCKET ?= terraform.agilestacks.com
STATE_REGION ?= us-east-1

export AWS_DEFAULT_REGION ?= us-east-2

export DOMAIN_NAME ?= test.dev.superhub.io

export TF_DATA_DIR ?= .terraform/$(TF_VAR_name)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log

terraform   ?= terraform-v0.12
TF_CLI_ARGS ?= -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan

export TF_VAR_subnet_ids := $(shell echo '$(SUBNET_IDS)' | jq -cR 'split(",")')
export TF_VAR_sg_ids     := $(shell echo '$(SG_IDS)' | jq -cR 'split(",")')

# If instance_type contains comma, ie. r5.large:1,m5.large:2,c5.large (implicit :1 weight)
# then it is Mixed ASG - with empty spot price that defaults on AWS side to on-demand price, or a specified spot price
# Else if spot price is set then it is a plain ASG with spot instances
# Else it is on-demand instances via native EKS nodegroup
comma := ,
WORKER_IMPL := $(if $(or $(findstring $(comma),$(TF_VAR_instance_type)),$(TF_VAR_spot_price)),autoscaling,nodegroup)

deploy: init import plan apply

$(TF_DATA_DIR):
	@rm -rf $@ && mkdir -p $@

init: $(TF_DATA_DIR)
	@cp -v eks-worker-$(WORKER_IMPL).tf.ignore eks-worker.tf
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(DOMAIN_NAME)/eks-worker-nodes/$(TF_VAR_name)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"

plan:
	$(terraform) plan $(TF_CLI_ARGS) -out=$(TFPLAN)

refresh:
	$(terraform) refresh $(TF_CLI_ARGS)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)

import: name2=$(shell echo $(TF_VAR_name) | tr . - | cut -c 1-63)
import:
	-test $(WORKER_IMPL) == autoscaling && \
		$(terraform) import $(TF_CLI_ARGS) aws_autoscaling_group.nodes eks-node-$(name2)
	-test $(WORKER_IMPL) == nodegroup && \
		$(terraform) import $(TF_CLI_ARGS) aws_eks_node_group.nodes $(TF_VAR_cluster_name):$(TF_VAR_short_name)

output:
	@$(terraform) output -no-color

undeploy: init import destroy apply

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

-include ../Mk/phonies
