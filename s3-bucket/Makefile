.DEFAULT_GOAL := deploy

TF_DATA_DIR        ?= .terraform/$(DOMAIN_NAME)-$(COMPONENT_NAME)
TF_LOG_PATH        ?= $(TF_DATA_DIR)/terraform.log
TF_VAR_name        := $(COMPONENT_NAME)
TF_OPTS            := -no-color
TF_INPUT           := 0
TF_IN_AUTOMATION   := 1 
TF_PLAN            := $(TF_DATA_DIR)/terraform.tfplan
terraform          := terraform-v0.12
jq                 := jq -M

export $(filter TF_%,$(.VARIABLES))

deploy: init plan
	$(MAKE) apply || \
	$(MAKE) import plan apply
	# hub cli doesn't support optional outputs
	test "true" = `$(terraform) output -json | $(jq) 'has("kms_key_id")'` || \
		echo "kms_key_id = "
	echo ""

# Terraform doesn't allow conditional nested objects
# and interpolation for resource lifecycle
ifeq (sse-kms,$(ENCRYPTION))
bucket.tf: TF_FILE:=bucket-kms.tf.ignore
else ifneq (,$(ENCRYPTION))
$(error Unsupported option '$(ENCRYPTION)'; today we only support 'sse-kms')
else
bucket.tf: TF_FILE:=bucket-$(RECLAIM).tf.ignore
endif

bucket.tf:
	cp -f $(TF_FILE) $@

init: bucket.tf
	rm -rf $(TF_DATA_DIR)
	mkdir -p $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(TF_OPTS) \
        -backend=true -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(DOMAIN_NAME)/s3-bucket/$(COMPONENT_NAME)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"

$(TF_PLAN):
	$(terraform) plan $(TF_OPTS) -refresh=true -out=$@

apply: $(TF_PLAN)
	$(terraform) apply $(TF_OPTS) -auto-approve $^

destroy: TF_OPTS+=-destroy
destroy: $(TF_PLAN)

undeploy: init destroy apply

import:
	$(terraform) import $(TF_OPTS) aws_s3_bucket.main $(TF_VAR_name)

clean:
	rm -rf $(TF_DATA_DIR) bucket.tf

ifeq ($(RECLAIM),retain)
# see https://github.com/hashicorp/terraform/issues/17599
.IGNORE: undeploy
endif
.INTERMEDIATE: $(TF_DATA_DIR) $(TF_PLAN)
.SILENT:       deploy $(TF_DATA_DIR)
.IGNORRE:      import destroy
.PHONY:        destroy bucket.tf

-include ../Mk/phonies
