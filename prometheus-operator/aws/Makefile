.DEFAULT_GOAL := deploy

DOMAIN_NAME    ?= dev.superhub.io
STATE_BUCKET   ?= terraform.agilestacks.io
STATE_REGION   ?= us-east-1
NAMESPACE      ?= monitoring
BUCKET_NAME    ?= thanos
IAM_USER       ?= thanos


export TF_OPTS               ?= -no-color
export TF_UPDATE             ?= -update
export TF_DATA_DIR           ?= .terraform
export TF_VAR_component      ?= prometheus-operator
export TF_VAR_namespace      := $(NAMESPACE)
export TF_VAR_domain		 := $(DOMAIN_NAME)
export TF_VAR_bucket_name	 := $(BUCKET_NAME)
export TF_VAR_username		 := $(IAM_USER)


# https://github.com/hashicorp/terraform/issues/14847
unexport TF_CLI_ARGS

terraform ?= terraform-v0.11

$(TF_DATA_DIR):
	mkdir -p "$@"

install: deploy

init: $(TF_DATA_DIR)
	$(terraform) init $(TF_OPTS) \
        -get=true -force-copy \
        -backend=true -input=false -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(DOMAIN_NAME)/prometheus-operator/$(COMPONENT_NAME)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"
.PHONY: init

deploy:
	$(MAKE) init plan apply || \
	$(MAKE) init plan apply output

undeploy:
	$(MAKE) init
	$(MAKE) plan TF_OPTS="-destroy -no-color"
	$(MAKE) apply

clean:
	rm -rf $(TF_DATA_DIR)

import:
	- $(terraform) import $(TF_OPTS) module.user.aws_iam_user.main agilestacks-$(TF_VAR_component)

plan:
	$(terraform) plan $(TF_OPTS) -refresh=true -module-depth=-1 -out=.terraform/terraform.tfplan

refresh:
	$(terraform) refresh $(TF_OPTS)

apply:
	$(terraform) apply $(TF_OPTS) -auto-approve .terraform/terraform.tfplan

output:
	@ $(terraform) output $(TF_OPTS)
	@ echo

-include ../../Mk/phonies
