.DEFAULT_GOAL := deploy

R53_SYNC_ZIP_FILE				 := lambda/asg-hook-sync/lambda.zip
export TF_VAR_component          ?= aws-drainer
export TF_VAR_domain_name        ?= test.dev.superhub.io
export TF_VAR_namespace          ?= aws-drainer
export TF_VAR_kubeconfig_context ?= $(TF_VAR_domain_name)
export TF_VAR_cluster_name          ?= defaul-cluster

export TF_LOG      ?= DEBUG
export TF_DATA_DIR ?= .terraform/$(TF_VAR_domain_name)-$(TF_VAR_component)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log

kubectl ?= kubectl --context="$(TF_VAR_domain_name)" --namespace="$(TF_VAR_namespace)"
terraform   ?= terraform-v0.11
TF_CLI_ARGS ?= -no-color -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan


ifneq (,$(filter $(CLOUD_KIND),aws hybrid))
STATE_BACKEND_CONFIG := -backend-config="bucket=$(STATE_BUCKET)" \
        		-backend-config="region=$(STATE_REGION)" \
				-backend-config="key=$(TF_VAR_domain_name)/$(TF_VAR_component)/terraform.tfstate" \
				-backend-config="profile=$(AWS_PROFILE)"
else
$(error cloud.kind / CLOUD_KIND must be one of: aws, hybrid)
endif


init: $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
		$(STATE_BACKEND_CONFIG) \
		./$(CLOUD_KIND)

$(TF_DATA_DIR):
	@mkdir -p $@

deploy: aws_lambda init plan apply install

install:
	- $(kubectl) create ns $(TF_VAR_namespace)
	- $(kubectl) apply -k base/
	- $(kubectl) apply -f kube-drainer.yaml

undeploy: init aws_lambda destroy apply
	- $(kubectl) delete -k base/
	- $(kubectl) delete -f kube-drainer.yaml

aws_lambda:
	$(MAKE) -C "lambda/asg-hook-sync"

plan:
	$(terraform) plan $(TF_CLI_ARGS) -refresh=true -module-depth=-1 -out=$(TFPLAN) ./$(CLOUD_KIND)

refresh:
	$(terraform) refresh $(TF_CLI_ARGS) ./$(CLOUD_KIND)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)
	@echo

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

-include ../Mk/phonies
