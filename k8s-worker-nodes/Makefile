.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= k8s-worker-nodes

DOMAIN_NAME    ?= viktor3.demo01.kubernetes.delivery
CLOUD_BUCKET   ?= files.$(DOMAIN_NAME)
STATE_BUCKET   ?= demo01.agilestacks.com
STATE_REGION   ?= eu-west-1
export AWS_DEFAULT_REGION ?= eu-central-1

NODE_POOL_NAME                 ?= gpu1
WORKER_INSTANCE_TYPE           ?= r4.large
WORKER_INSTANCE_COUNT          ?= 2
WORKER_INSTANCE_SPOT_PRICE     ?= 0.15
WORKER_CONTAINER_LINUX_VERSION ?= 1800.5.0

AWS_WORKER_SECURITY_GROUP_ID ?= sg-0d0f47844b86b151d
AWS_WORKER_SUBNET_ID ?= subnet-0596d28123e4cc821

export TF_LOG             ?= debug
export TF_OPTS            ?= -no-color
export TF_UPDATE          ?= -update
export TF_LOG_PATH        := .terraform/$(DOMAIN_NAME)/$(notdir $(COMPONENT_NAME))-$(NODE_POOL_NAME).log
export TF_VAR_base_domain := $(DOMAIN_NAME)
export TF_VAR_node_pool_name := $(NODE_POOL_NAME)
export TF_VAR_s3_files_worker_bucket := $(CLOUD_BUCKET)
export TF_VAR_worker_sg_ids := ["$(AWS_WORKER_SECURITY_GROUP_ID)"]
export TF_VAR_worker_subnet_ids :=  ["$(AWS_WORKER_SUBNET_ID)"]
export TF_VAR_worker_instance_type := $(WORKER_INSTANCE_TYPE)
export TF_VAR_worker_instance_count := $(WORKER_INSTANCE_COUNT)
export TF_VAR_worker_spot_price := $(WORKER_INSTANCE_SPOT_PRICE)
export TF_VAR_container_linux_version := $(WORKER_CONTAINER_LINUX_VERSION)
export TF_VAR_cluster_tag := $(shell sed 's/\./-/' <<< $(TF_VAR_base_domain))

terraform ?= terraform-v0.11
TFPLAN ?= .terraform/$(TF_VAR_base_domain)/$(notdir $(COMPONENT_NAME))-$(NODE_POOL_NAME).tfplan

deploy: init import plan apply

init:
	@mkdir -p .terraform/$(TF_VAR_base_domain)
	$(terraform) init -get=true $(TF_CMD_OPTS) -reconfigure -force-copy  \
		-backend=true -input=false \
		-backend-config="bucket=$(STATE_BUCKET)" \
		-backend-config="region=$(STATE_REGION)" \
		-backend-config="key=$(TF_VAR_base_domain)/$(notdir $(COMPONENT_NAME))-$(NODE_POOL_NAME)/terraform.tfstate" \
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

undeploy: init
	$(MAKE) plan TF_OPTS=-destroy
	$(MAKE) apply
.PHONY: undeploy

import:
	-$(terraform) import $(TF_OPTS) aws_autoscaling_group.workers workers-$(NODE_POOL_NAME)-$(TF_VAR_base_domain) 2>/dev/null
	-$(terraform) import $(TF_OPTS) aws_iam_instance_profile.worker_profile worker-profile-$(NODE_POOL_NAME)-$(TF_VAR_base_domain) 2>/dev/null
	-$(terraform) import $(TF_OPTS) aws_launch_configuration.worker_conf worker-conf-$(NODE_POOL_NAME)-$(TF_VAR_base_domain) 2>/dev/null
	-$(terraform) import $(TF_OPTS) aws_iam_role.worker_role worker_role-$(NODE_POOL_NAME)-$(TF_VAR_base_domain) 2>/dev/null
	-$(terraform) import $(TF_OPTS) aws_iam_role_policy.worker_policy worker_policy-$(NODE_POOL_NAME)-$(TF_VAR_base_domain) 2>/dev/null
.PHONY: import
