.DEFAULT_GOAL := deploy

DEFAULT_GATEWAY_ZONE ?= mesh
DEFAULT_INGRESS_GATEWAY ?= ingressgateway
export TF_VAR_domain       := $(DOMAIN_NAME)
export TF_VAR_service_name := $(COMPONENT_NAME)-ingressgateway
export TF_VAR_namespace    := $(NAMESPACE)
export TF_VAR_record       := $(DEFAULT_GATEWAY_ZONE)
export TF_DATA_DIR         := .terraform

kubectl := kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
jq := jq -cM
terraform   ?= terraform-v0.11

TF_CLI_ARGS ?= -no-color -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan
TIMEOUT     ?= 600

$(TF_DATA_DIR):
	@rm -rf $@ && mkdir -p $@

init: $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(DOMAIN_NAME)/$(COMPONENT_NAME)/$(DEFAULT_INGRESS_GATEWAY)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"

plan:
	$(terraform) plan $(TF_CLI_ARGS) -refresh=true -module-depth=-1 -out=$(TFPLAN)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

undeploy: init destroy apply
deploy: init plan apply
