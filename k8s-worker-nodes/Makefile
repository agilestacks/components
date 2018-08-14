.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= k8s-worker-nodes

export AWS_DEFAULT_REGION ?= eu-central-1

CLOUD_BUCKET   ?= files.$(TF_VAR_base_domain)

export TF_LOG             ?= info
export TF_OPTS            ?= -no-color
export TF_UPDATE          ?= -update
export TF_LOG_PATH        := .terraform/$(TF_VAR_base_domain)/$(notdir $(COMPONENT_NAME))-$(TF_VAR_node_pool_name).log
export TF_VAR_s3_files_worker_bucket := $(CLOUD_BUCKET)
export TF_VAR_cluster_tag := $$(TF_VAR_base_domain/./-)

terraform ?= terraform-v0.11
TFPLAN ?= .terraform/$(TF_VAR_base_domain)/$(notdir $(COMPONENT_NAME))-$(TF_VAR_node_pool_name).tfplan

kubectl ?= kubectl --context="$(TF_VAR_base_domain)" --namespace=kube-system

deploy: init import plan apply kubernetes

init:
	@mkdir -p .terraform/$(TF_VAR_base_domain)
	$(terraform) init -reconfigure -input=false -get=true -force-copy $(TF_OPTS) \
		-backend=true \
		-backend-config="bucket=$(TF_VAR_state_bucket)" \
		-backend-config="region=$(TF_VAR_state_region)" \
		-backend-config="key=$(TF_VAR_base_domain)/$(notdir $(COMPONENT_NAME))-$(TF_VAR_node_pool_name)/terraform.tfstate" \
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

# we should make it a part of stack-k8s-aws? then what about eks?
kubernetes:
	$(kubectl) apply -f nvidia-gpu-device-plugin.yml
.PHONY: kubernetes

undeploy: init destroy apply

destroy: TF_OPTS=-destroy
destroy: plan

import:
	-$(terraform) import $(TF_OPTS) aws_autoscaling_group.workers workers-$(TF_VAR_node_pool_name)-$(TF_VAR_base_domain) 2>/dev/null
	-$(terraform) import $(TF_OPTS) aws_iam_instance_profile.worker_profile worker-profile-$(TF_VAR_node_pool_name)-$(TF_VAR_base_domain) 2>/dev/null
	-$(terraform) import $(TF_OPTS) aws_iam_role.worker_role worker_role-$(TF_VAR_node_pool_name)-$(TF_VAR_base_domain) 2>/dev/null
	-$(terraform) import $(TF_OPTS) aws_iam_role_policy.worker_policy worker_policy-$(TF_VAR_node_pool_name)-$(TF_VAR_base_domain) 2>/dev/null
.PHONY: import
