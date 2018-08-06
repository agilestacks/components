.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= k8s-worker-nodes

DOMAIN_NAME    ?= voacc1.demo01.kubernetes.delivery
CLUSTER_NAME ?= vokube
NODE_TYPE ?= gpu2
STATE_BUCKET   ?= demo01.agilestacks.com
STATE_REGION   ?= eu-west-1
export AWS_PROFILE        ?= agilestacks-demo01
export AWS_DEFAULT_REGION ?= eu-central-1
WORKER_INSTANCE_TYPE ?= r4.large
WORKER_INSTANCE_COUNT ?= 2
WORKER_INSTANCE_SPOT_PRICE ?= 0.15
WORKER_CONTAINER_LINUX_VERSION ?= 1800.5.0

AWS_WORKER_SECURITY_GROUP_IDS ?= ["sg-a7c955cb"]
AWS_WORKER_SUBNET_IDS ?= ["subnet-805f57eb"] 

export TF_LOG             ?= debug
export TF_OPTS            ?= -no-color
export TF_UPDATE          ?= -update
export TF_LOG_PATH        := .terraform/$(DOMAIN_NAME)/$(notdir $(COMPONENT_NAME))-$(CLUSTER_NAME)-$(NODE_TYPE).log
export TF_VAR_base_domain := $(DOMAIN_NAME)
export TF_VAR_cluster_name := $(CLUSTER_NAME)
export TF_VAR_node_type := $(NODE_TYPE)
export TF_VAR_aws_s3_files_worker_bucket := files.$(CLUSTER_NAME).$(TF_VAR_base_domain)
export TF_VAR_aws_worker_sg_ids := $(AWS_WORKER_SECURITY_GROUP_IDS)
export TF_VAR_aws_worker_subnet_ids :=  $(AWS_WORKER_SUBNET_IDS)
export TF_VAR_aws_worker_iam_role := worker-role-$(CLUSTER_NAME)-$(TF_VAR_base_domain)
export TF_VAR_worker_instance_type := $(WORKER_INSTANCE_TYPE)
export TF_VAR_worker_count := $(WORKER_INSTANCE_COUNT)
export TF_VAR_worker_spot_price := $(WORKER_INSTANCE_SPOT_PRICE)
export TF_VAR_asi_container_linux_version := $(WORKER_CONTAINER_LINUX_VERSION)

terraform ?= terraform-v0.11
TFPLAN ?= .terraform/$(notdir $(COMPONENT_NAME)).tfplan

deploy: init import plan apply

init:
	@mkdir -p .terraform/$(TF_VAR_base_domain)
	$(terraform) init -get=true $(TF_CMD_OPTS) -reconfigure -force-copy  \
		-backend=true -input=false \
		-backend-config="bucket=$(STATE_BUCKET)" \
		-backend-config="region=$(STATE_REGION)" \
		-backend-config="key=$(TF_VAR_base_domain)/$(notdir $(COMPONENT_NAME))-$(NODE_TYPE)/terraform.tfstate" \
		-backend-config="profile=$(AWS_PROFILE)" \
		platforms/aws
.PHONY: init

get:
	$(terraform) get $(TF_UPDATE)
.PHONY: get

plan:
	$(terraform) plan $(TF_OPTS) -refresh=true -module-depth=-1 -out=$(TFPLAN) platforms/aws
.PHONY: plan

apply:
	$(terraform) apply $(TF_OPTS) -Xshadow=false $(TFPLAN)
.PHONY: apply

undeploy: init
	$(MAKE) plan TF_OPTS=-destroy
	$(MAKE) apply
.PHONY: undeploy

import:
	-$(terraform) import $(TF_OPTS) -config=platforms/aws module.workers.aws_autoscaling_group.workers workers-$(CLUSTER_NAME)-$(NODE_TYPE)-$(TF_VAR_base_domain) 2>/dev/null
	-$(terraform) import $(TF_OPTS) -config=platforms/aws module.workers.aws_iam_instance_profile.worker_profile worker-profile-$(CLUSTER_NAME)-$(NODE_TYPE)-$(TF_VAR_base_domain) 2>/dev/null
	-$(terraform) import $(TF_OPTS) -config=platforms/aws module.workers.aws_launch_configuration.worker_conf worker-conf-$(CLUSTER_NAME)-$(NODE_TYPE)-$(TF_VAR_base_domain) 2>/dev/null
.PHONY: import
