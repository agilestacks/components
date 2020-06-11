.DEFAULT_GOAL := deploy


COMPONENT_NAME          ?= aws-spot-data-feed
DOMAIN_NAME             ?= test.dev.superhub.io
TF_DATA_DIR             ?= .terraform/$(COMPONENT_NAME)
TF_LOG_PATH             ?= $(TF_DATA_DIR)/terraform.log
TF_CLI_ARGS             ?= -no-color -input=false
TFPLAN                  := $(TF_DATA_DIR)/terraform.tfplan
TFSTATE                 := $(TF_DATA_DIR)/terraform.tfstate

terraform      ?= terraform-v0.12

deploy: init import plan apply

init: $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(DOMAIN_NAME)/aws-spot-data-feed/$(COMPONENT_NAME)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"

$(TF_DATA_DIR):
	@rm -rf $@ && mkdir -p $@


import:
	-$(terraform) import $(TF_CLI_ARGS) aws_spot_datafeed_subscription.aws-spot-data-feed spot-datafeed-subscription


plan:
	$(terraform) plan $(TF_CLI_ARGS) -refresh=true -state="$(TFSTATE)" -out="$(TFPLAN)"

refresh:
	$(terraform) refresh $(TF_CLI_ARGS)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve -state-out="$(TFSTATE)" "$(TFPLAN)"



undeploy: init destroy apply

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

-include ../Mk/phonies
