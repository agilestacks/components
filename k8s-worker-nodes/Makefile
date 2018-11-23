.DEFAULT_GOAL := deploy

STATE_BUCKET ?= terraform.agilestacks.com
STATE_REGION ?= us-east-1

export AWS_DEFAULT_REGION ?= us-east-2

export TF_VAR_domain    ?= dev.kubernetes.delivery
export TF_VAR_pool_name ?= gpu1
export TF_VAR_s3_bucket := files.$(TF_VAR_domain)

export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(TF_VAR_domain)-$(TF_VAR_pool_name)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log

kubectl     ?= kubectl --context="$(TF_VAR_domain)" --namespace=kube-system
terraform   ?= terraform-v0.11
TF_CLI_ARGS ?= -no-color -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan

deploy: init import plan apply kubernetes

$(TF_DATA_DIR):
	@rm -rf $@ && mkdir -p $@

init: $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(TF_VAR_domain)/k8s-worker-nodes/$(TF_VAR_pool_name)/terraform.tfstate" \
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
	$(eval WORKERS=$(shell echo workers-$(TF_VAR_pool_name)-$(TF_VAR_domain) | cut -c 0-63))
	-$(terraform) import $(TF_OPTS) aws_autoscaling_group.workers $(WORKERS)

-include ../Mk/phonies
