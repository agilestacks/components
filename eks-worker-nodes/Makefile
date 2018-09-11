.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= eks-worker-nodes

export AWS_PROFILE        ?= default
export AWS_DEFAULT_REGION ?= us-east-2

export TF_VAR_domain    ?= 'dev.kubernetes.delivery'
export TF_VAR_pool_name ?= gpu1

export TF_LOG      ?= info
export TF_OPTS     ?= -no-color
export TF_UPDATE   ?= -update
export TF_LOG_PATH := .terraform/$(TF_VAR_domain)/$(notdir $(COMPONENT_NAME))-$(TF_VAR_pool_name).log
TFPLAN             ?= .terraform/$(TF_VAR_domain)/$(notdir $(COMPONENT_NAME))-$(TF_VAR_pool_name).tfplan

# kubectl   ?= kubectl --context="$(TF_VAR_domain)" --namespace=kube-system
terraform ?= terraform-v0.11

deploy: init plan apply

init:
	@mkdir -p .terraform/$(TF_VAR_domain)
	$(terraform) init -reconfigure -input=false -get=true -force-copy $(TF_OPTS) \
		-backend=true \
		-backend-config="bucket=$(STATE_BUCKET)" \
		-backend-config="region=$(STATE_REGION)" \
		-backend-config="key=$(TF_VAR_domain)/eks-worker-nodes/$(notdir $(COMPONENT_NAME))-$(TF_VAR_pool_name)/terraform.tfstate" \
		-backend-config="profile=$(AWS_PROFILE)"
.PHONY: init

get:
	$(terraform) get $(TF_UPDATE)
.PHONY: get

plan:
	$(terraform) plan $(TF_OPTS) \
		-refresh=true \
		-module-depth=-1 \
		-out=$(TFPLAN)
.PHONY: plan

apply:
	$(terraform) apply $(TF_OPTS) -Xshadow=false $(TFPLAN)
.PHONY: apply

undeploy: init destroy apply

destroy: TF_OPTS=-destroy
destroy: plan

# import:
# 	$(eval WORKERS=$(shell echo workers-$(TF_VAR_pool_name)-$(TF_VAR_domain) | cut -c 0-63))
# 	-$(terraform) import $(TF_OPTS) aws_autoscaling_group.workers $(WORKERS) 2>/dev/null
# .PHONY: import
