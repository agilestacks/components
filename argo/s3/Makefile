.DEFAULT_GOAL := deploy

DOMAIN_NAME    ?= dev.stacks.delivery
STATE_BUCKET   ?= terraform.agilestacks.com
STATE_REGION   ?= us-east-1
NAMESPACE      ?= argoproj
BUCKET         ?= default
ACCESS_KEY_REF ?= accesskey
SECRET_KEY_REF ?= secretkey

export TF_OPTS               ?= -no-color
export TF_UPDATE             ?= -update
export TF_DATA_DIR           ?= .terraform
export TF_VAR_component      ?= argo
export TF_VAR_namespace      := $(NAMESPACE)
export KUBE_CTX              := $(DOMAIN_NAME)

export TF_VAR_bucket_name    ?= $(BUCKET)
export TF_VAR_component      ?= argo
export TF_VAR_access_key_ref ?= $(ACCESS_KEY_REF)
export TF_VAR_secret_key_ref ?= $(SECRET_KEY_REF)

# https://github.com/hashicorp/terraform/issues/14847
unexport TF_CLI_ARGS

terraform ?= terraform-v0.11

$(TF_DATA_DIR):
	mkdir -p "$@"

init: $(TF_DATA_DIR)
	$(terraform) init $(TF_OPTS) \
        -get=true -force-copy \
        -backend=true -input=false -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(DOMAIN_NAME)/argo/$(COMPONENT_NAME)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"
.PHONY: init

deploy:
	$(MAKE) init plan apply || \
	$(MAKE) init plan apply output
.PHONY: deploy

undeploy:
	$(MAKE) plan TF_OPTS="-destroy -no-color"
	$(MAKE) apply
.PHONY: undeploy

clean:
	rm -rf $(TF_DATA_DIR)

import:
	- $(terraform) import $(TF_OPTS) module.user.aws_iam_user.main agilestacks-$(TF_VAR_component)
	- $(terraform) import $(TF_OPTS) kubernetes_secret.aws $(TF_VAR_namespace)/argo-repo-$(TF_VAR_component)
.PHONY: import

plan:
	$(terraform) plan $(TF_OPTS) -refresh=true -module-depth=-1 -out=.terraform/terraform.tfplan
.PHONY: plan

refresh:
	$(terraform) refresh $(TF_OPTS)
.PHONY: refresh

apply:
	$(terraform) apply $(TF_OPTS) -auto-approve .terraform/terraform.tfplan
.PHONY: apply

output:
	@ $(terraform) output $(TF_OPTS)
	@ echo
.PHONY: output
