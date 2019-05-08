SHELL := /bin/bash
.DEFAULT_GOAL := deploy

DOMAIN_NAME    ?= supergke.gcp.superhub.io
COMPONENT_NAME ?= k8s-gke

NAME           := $(shell echo $(DOMAIN_NAME) | cut -d. -f1)
BASE_DOMAIN    := $(shell echo $(DOMAIN_NAME) | cut -d. -f2-)

STATE_BUCKET ?= gcp-superhub-io
STATE_REGION ?= us-central1

SERVICE_ACCOUNT ?= asi

LOCATION := $(REGION)
LOCATION_KIND :=--region
ifneq (,$(ZONE))
	LOCATION=$(ZONE)
	LOCATION_KIND=--zone
endif

export TF_VAR_base_domain ?= $(BASE_DOMAIN)
export TF_VAR_project ?= superhub
export TF_VAR_region ?= us-central1
export TF_VAR_cluster_name := $(CLUSTER_NAME)
export TF_VAR_location := $(LOCATION)
export TF_VAR_name := $(NAME)

terraform   ?= terraform-v0.11
export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(DOMAIN_NAME)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log
TF_CLI_ARGS := -no-color -input=false -lock=false
TFPLAN := $(TF_DATA_DIR)/$(DOMAIN_NAME).tfplan

gcloud ?= gcloud
kubectl ?= kubectl

init:
	@mkdir -p $(TF_DATA_DIR)
	$(terraform) init -get=true $(TF_CLI_ARGS) -reconfigure -force-copy \
		-backend-config="bucket=$(STATE_BUCKET)" \
		-backend-config="prefix=$(DOMAIN_NAME)/$(COMPONENT_NAME)"

plan:
	$(terraform) plan $(TF_CLI_ARGS) \
		-refresh=true -module-depth=-1 -out=$(TFPLAN)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -Xshadow=false $(TFPLAN)

gcontext:	
	$(gcloud) container clusters get-credentials $(CLUSTER_NAME) $(LOCATION_KIND) $(TF_VAR_location)

createsa: gcontext
	@if $(kubectl) get -n default serviceaccount $(SERVICE_ACCOUNT) ; then \
		echo "Service Account $(SERVICE_ACCOUNT) exists"; \
	else \
		$(kubectl) create -n default serviceaccount $(SERVICE_ACCOUNT); \
	fi	
	@if $(kubectl) get clusterrolebinding $(SERVICE_ACCOUNT)-cluster-admin-binding ; then \
		echo "Clusterrolebinding $(SERVICE_ACCOUNT)-cluster-admin-binding exists"; \
	else \
		$(kubectl) create clusterrolebinding $(SERVICE_ACCOUNT)-cluster-admin-binding \
			--clusterrole=cluster-admin --serviceaccount=default:$(SERVICE_ACCOUNT); \
	fi
	@sleep 10s

token:
	$(eval SECRET=$(shell $(kubectl) get serviceaccount $(SERVICE_ACCOUNT) -o json | \
		jq '.secrets[] | select(.name | contains("token")).name'))
	$(eval TOKEN_BASE64=$(shell $(kubectl) get secret $(SECRET) -o json | \
		jq '.data.token'))	
	$(eval TOKEN=$(shell openssl enc -A -base64 -d <<< $(TOKEN_BASE64)))

deletesa: gcontext
	$(kubectl) delete clusterrolebinding $(SERVICE_ACCOUNT)-cluster-admin-binding
	$(kubectl) delete -n default serviceaccount $(SERVICE_ACCOUNT)

region:
	$(eval REGION=$(shell echo $(LOCATION) | cut -d- -f1-2))

output:
	@echo
	@echo Outputs:
	@echo dns_name = $(NAME)
	@echo dns_base_domain = $(BASE_DOMAIN)
	@echo token = $(TOKEN)
	@echo region = $(REGION)
	@echo
.PHONY: output

deploy: init plan apply createsa token output

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan	

undeploy: deletesa init destroy apply
