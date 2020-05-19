.DEFAULT_GOAL := deploy

export TF_VAR_name										?= public-dns
export TF_VAR_base_domain 						?= gov-01.dev.superhub.io
export TF_VAR_aws_access_key_id 			?=
export TF_VAR_aws_secret_access_key   ?=

DOMAIN_NAME										:= $(TF_VAR_name).$(TF_VAR_base_domain)
COMPONENT_NAME								?= dns-zone
STATE_BUCKET 	                ?= agilestacks.gov-01.dev.superhub.io
STATE_REGION                  ?= us-gov-east-1

TF_CLI_ARGS 	 		        		?= -no-color -input=false
export TF_DATA_DIR            ?= .terraform/$(DOMAIN_NAME)-$(COMPONENT_NAME)
TFPLAN      									:= $(TF_DATA_DIR)/terraform.tfplan

terraform                     ?= terraform-v0.12

$(TF_DATA_DIR):
	@rm -rf $@ && mkdir -p $@

provider:
	rm -f this-account.tf external-account.tf
	if [ "$(AWS_DNS_CREDENTIALS_ENABLED)" == "true" ]; then \
		cp providers/external-account.tf . ;\
	else \
		cp providers/this-account.tf . ; \
	fi

import:
	$(eval export zone_id := $(shell bin/route53-zone-by-domain.sh $(DOMAIN_NAME)))
	$(eval export parent_zone_id := $(shell bin/route53-zone-by-domain.sh $(TF_VAR_base_domain)))
	-test -n "$$zone_id" && \
		$(terraform) import $(TF_CLI_ARGS) aws_route53_zone.current $(zone_id)
	-test -n "$$parent_zone_id" && \
		$(terraform) import $(TF_CLI_ARGS) aws_route53_record.parent $(parent_zone_id)_$(DOMAIN_NAME)_NS

init: $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
	-backend=true -reconfigure \
	-backend-config="bucket=$(STATE_BUCKET)" \
	-backend-config="region=$(STATE_REGION)" \
	-backend-config="key=$(DOMAIN_NAME)/$(COMPONENT_NAME)/terraform.tfstate" \
	-backend-config="profile=$(AWS_PROFILE)"

plan:
	$(terraform) plan $(TF_CLI_ARGS) -refresh=true -out=$(TFPLAN)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

deploy: provider init import plan apply

undeploy: provider init import destroy apply
