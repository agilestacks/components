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
DEFAULT_ZONE := $(REGION)-b
ifneq (,$(ZONE))
	LOCATION := $(ZONE)
	LOCATION_KIND := --zone
	DEFAULT_ZONE := $(ZONE)
endif

export TF_VAR_base_domain ?= $(BASE_DOMAIN)
export TF_VAR_project ?= superhub
export TF_VAR_region ?= us-central1
export TF_VAR_cluster_name := $(CLUSTER_NAME)
export TF_VAR_location := $(LOCATION)
export TF_VAR_name := $(NAME)

terraform ?= terraform-v0.11

export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(DOMAIN_NAME)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log
TF_CLI_ARGS := -no-color -input=false -lock=false
TFPLAN := $(TF_DATA_DIR)/$(DOMAIN_NAME).tfplan

PROJECT ?= $(TF_VAR_project)

gcloud ?= gcloud
kubectl ?= kubectl --context=gke_$(PROJECT)_$(LOCATION)_$(CLUSTER_NAME)

init:
	@mkdir -p $(TF_DATA_DIR)
	$(terraform) init -get=true $(TF_CLI_ARGS) -reconfigure -force-copy \
		-backend-config="bucket=$(STATE_BUCKET)" \
		-backend-config="prefix=$(DOMAIN_NAME)/$(COMPONENT_NAME)"
.PHONY: init

plan:
	$(terraform) plan $(TF_CLI_ARGS) \
		-refresh=true -module-depth=-1 -out=$(TFPLAN)
.PHONY: plan

apply:
	$(terraform) apply $(TF_CLI_ARGS) -Xshadow=false $(TFPLAN)
.PHONY: apply

gcontext:
	$(gcloud) container clusters get-credentials $(CLUSTER_NAME) $(LOCATION_KIND) $(TF_VAR_location)
.PHONY: gcontext

check:
	$(eval EXISTING_DOMAIN:=$(shell $(kubectl) get stackinfo asi-metadata -o json | jq -r .spec.domainName))
	@if [ "$(EXISTING_DOMAIN)" != "" ] && [ "$(EXISTING_DOMAIN)" != "$(DOMAIN_NAME)" ]; then\
    echo "Error: This cluster has already been imported using domain name: $(EXISTING_DOMAIN)";\
		echo "Error: Change of the domain name is not supported. This deployment will fail...";\
		exit 1;\
  fi
.PHONY: check

createsa: gcontext check
	$(kubectl) get -n default serviceaccount $(SERVICE_ACCOUNT) || \
		($(kubectl) create -n default serviceaccount $(SERVICE_ACCOUNT) && sleep 7)
	$(kubectl) get clusterrolebinding $(SERVICE_ACCOUNT)-cluster-admin-binding || \
		($(kubectl) create clusterrolebinding $(SERVICE_ACCOUNT)-cluster-admin-binding \
			--clusterrole=cluster-admin --serviceaccount=default:$(SERVICE_ACCOUNT) && sleep 7)
.PHONY: createsa

storage:
	$(kubectl) apply -f storage-class.yaml
.PHONY: storage

token:
	$(eval SECRET=$(shell $(kubectl) get serviceaccount $(SERVICE_ACCOUNT) -o json | \
		jq '.secrets[] | select(.name | contains("token")).name'))
	$(eval TOKEN=$(shell $(kubectl) get secret $(SECRET) -o json | \
		jq '.data.token'))
.PHONY: token

deletesa: gcontext
	$(kubectl) delete clusterrolebinding $(SERVICE_ACCOUNT)-cluster-admin-binding
	$(kubectl) delete -n default serviceaccount $(SERVICE_ACCOUNT)
.PHONY: deletesa

region:
	$(eval REGION=$(shell echo $(LOCATION) | cut -d- -f1-2))
.PHONY: region

output:
	@echo
	@echo Outputs:
	@echo dns_name = $(NAME)
	@echo dns_base_domain = $(BASE_DOMAIN)
	@echo token = $(TOKEN) | $(HUB) util otp
	@echo region = $(REGION)
	@echo zone = $(DEFAULT_ZONE)
	@echo
.PHONY: output

deploy: createsa storage region init plan apply token output

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

undeploy: gcontext check init destroy apply deletesa
