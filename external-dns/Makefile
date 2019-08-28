.DEFAULT_GOAL := deploy

export TF_VAR_component          ?= external-dns
export TF_VAR_domain_name        ?=
export NAMESPACE                 ?= kube-system

CLOUD_KIND          ?= hybrid
ACM_CERTIFICATE_ARN ?=

STATE_BUCKET    ?= terraform.agilestacks.com
STATE_REGION    ?= us-east-1
STATE_CONTAINER ?= agilestacks

export AWS_DEFAULT_REGION ?= us-east-1

export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(TF_VAR_domain_name)-$(TF_VAR_component)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log

terraform   ?= terraform-v0.11
TF_CLI_ARGS ?= -no-color -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan
KUBECONFIG := kubectl --context="$(TF_VAR_domain_name)" --namespace="$(NAMESPACE)"

deploy: init purge plan apply install

ifneq (,$(filter $(CLOUD_KIND), aws hybrid))
STATE_BACKEND_CONFIG := -backend-config="bucket=$(STATE_BUCKET)" \
        		-backend-config="region=$(STATE_REGION)" \
				-backend-config="key=$(TF_VAR_domain_name)/$(TF_VAR_component)/terraform.tfstate" \
				-backend-config="profile=$(AWS_PROFILE)"
else
	$(error cloud.kind / CLOUD_KIND must be either aws or hybrid)
endif


$(TF_DATA_DIR):
	@mkdir -p $@

init: $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
        $(STATE_BACKEND_CONFIG)

purge:
	-$(KUBECONFIG) delete -f manifests.yaml

install:
	$(eval HOSTED_ZONE_ID = $(shell TF_DATA_DIR=$(TF_DATA_DIR) $(terraform) output hosted_zone_id))
	sed -i'' "s/%%HOSTED_ZONE_ID%%/$(HOSTED_ZONE_ID)/g" manifests.yaml
	$(KUBECONFIG) apply -f manifests.yaml

plan:
	$(terraform) plan $(TF_CLI_ARGS) -refresh=true -module-depth=-1 -out=$(TFPLAN)

refresh:
	$(terraform) refresh $(TF_CLI_ARGS)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)
	@echo

undeploy: purge

-include ../Mk/phonies
