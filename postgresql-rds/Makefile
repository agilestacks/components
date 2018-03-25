.DEFAULT_GOAL := deploy

export COMPONENT_NAME     	 ?= postgres-rds
export TF_VAR_rds_name    	 ?= postgresql
export TF_VAR_name        	 ?= dev
export TF_VAR_base_domain 	 ?= kubernetes.delivery
export AWS_PROFILE        	 ?= default
export AWS_DEFAULT_REGION 	 ?= us-east-2
export TF_VAR_base_domain  	 ?= stacks.delivery
export TF_LOG             	 ?= debug
export TF_LOG_PATH        	 ?= .terraform/$(TF_VAR_rds_name).$(TF_VAR_name).$(TF_VAR_base_domain).log
export TF_OPTS            	 ?= -no-color
export TF_UPDATE          	 ?= -update

export terraform          	 ?= terraform

export STATE_BUCKET ?= terraform.agilestacks.com
export STATE_REGION ?= us-east-1

# export TF_VAR_snapshot_identifier ?= postgresql-2017-12-06-12-19
export TS                    ?= $(shell date +"%Y-%m-%d-%H-%M")

deploy: init plan apply

init:
	@mkdir -p .terraform/$(TF_VAR_rds_name).$(TF_VAR_name).$(TF_VAR_base_domain)
	@rm -rf .terraform/$(TF_VAR_rds_name).$(TF_VAR_name).$(TF_VAR_base_domain)/*
	yes yes | $(terraform) init -get=true $(TF_OPTS) -force-copy  \
		-backend=true -input=false \
		-backend-config="bucket=$(STATE_BUCKET)" \
		-backend-config="region=$(STATE_REGION)" \
		-backend-config="key=$(COMPONENT_NAME)/$(TF_VAR_rds_name).$(TF_VAR_name).$(TF_VAR_base_domain)/terraform.tfstate" \
		-backend-config="profile=$(AWS_PROFILE)" \
		. .terraform/$(TF_VAR_rds_name).$(TF_VAR_name).$(TF_VAR_base_domain)
.PHONY: init

get:
	cd .terraform/$(TF_VAR_rds_name).$(TF_VAR_name).$(TF_VAR_base_domain) && \
		$(terraform) get $(TF_UPDATE)
.PHONY: get

plan:
	cd .terraform/$(TF_VAR_rds_name).$(TF_VAR_name).$(TF_VAR_base_domain) && \
		$(terraform) plan $(TF_OPTS) -refresh=true -module-depth=-1 -out=terraform.tfplan
.PHONY: plan

apply:
	cd .terraform/$(TF_VAR_rds_name).$(TF_VAR_name).$(TF_VAR_base_domain) && \
		$(terraform) apply $(TF_OPTS) -Xshadow=false terraform.tfplan
.PHONY: apply

backup:
	cd backup && \
		rm terraform.* && \
		mkdir -p ./.terraform && \
		rm -rf ./.terraform/* ./backup.tf ./output.tf && \
		templater.sh ./backup.tf.template > ./backup.tf && \
		templater.sh ./output.tf.template > ./output.tf && \
		$(terraform) init $(TF_OPTS) && \
		$(terraform) plan $(TF_OPTS) -refresh=true -module-depth=-1 -out=terraform.tfplan && \
		$(terraform) apply $(TF_OPTS) -Xshadow=false terraform.tfplan
.PHONY: backup

undeploy: import
	cd .terraform/$(TF_VAR_rds_name).$(TF_VAR_name).$(TF_VAR_base_domain) && \
		$(terraform) plan $(TF_OPTS) -destroy -refresh=true -module-depth=-1 -out=terraform.tfplan
	$(MAKE) apply
.PHONY: undeploy

import: init
	-cd .terraform/$(TF_VAR_rds_name).$(TF_VAR_name).$(TF_VAR_base_domain) && \
		terraform import aws_db_instance.postgresql $(TF_VAR_rds_name)
.PHONY: import

