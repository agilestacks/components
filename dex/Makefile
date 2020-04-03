.DEFAULT_GOAL := deploy

DOMAIN_NAME    ?= test.dev.superhub.io
NAMESPACE      ?= kube-system

STATE_BUCKET    ?= terraform.agilestacks.com
STATE_REGION    ?= us-east-1
STATE_CONTAINER ?= agilestacks

CLOUD_KIND ?= aws

export AWS_DEFAULT_REGION ?= us-east-2

export TF_VAR_domain_name                   := $(DOMAIN_NAME)
export TF_VAR_load_balancer                 ?=
export TF_VAR_load_balancer_dns_record_type ?= CNAME
export TF_VAR_azure_resource_group_name     ?= superhub-eastus2

export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(DOMAIN_NAME)-$(COMPONENT_NAME)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log

terraform   ?= terraform-v0.11
TF_CLI_ARGS ?= -no-color -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan
kubectl := kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"


ifneq (,$(filter tls-ingress,$(HUB_PROVIDES)))
	INGRESS:=ingress-tls
else
	INGRESS:=ingress
endif

deploy: clean install

# If external-dns is present, then we rely on our ingress to create the 'auth' subdomain.
# Otherewise we use terraform
ifeq (,$(filter external-dns,$(HUB_PROVIDES)))
deploy: init plan apply
undeploy: init destroy apply
endif

ifeq ($(CLOUD_KIND),aws)
STATE_BACKEND_CONFIG := -backend-config="bucket=$(STATE_BUCKET)" \
        		-backend-config="region=$(STATE_REGION)" \
				-backend-config="key=$(DOMAIN_NAME)/$(COMPONENT_NAME)/terraform.tfstate" \
				-backend-config="profile=$(AWS_PROFILE)"
else ifeq ($(CLOUD_KIND),gcp)
STATE_BACKEND_CONFIG := -backend-config="bucket=$(STATE_BUCKET)" \
        		-backend-config="region=$(STATE_REGION)" \
				-backend-config="prefix=$(DOMAIN_NAME)/$(COMPONENT_NAME)" \
				-backend-config="credentials=$(GOOGLE_APPLICATION_CREDENTIALS)"
else ifeq ($(CLOUD_KIND),azure)
STATE_BACKEND_CONFIG := -backend-config="storage_account_name=$(STATE_BUCKET)" \
				-backend-config="container_name=$(STATE_CONTAINER)" \
				-backend-config="resource_group_name=$(TF_VAR_azure_resource_group_name)" \
				-backend-config="key=$(DOMAIN_NAME)/$(COMPONENT_NAME)/terraform.tfstate"
else ifneq ($(CLOUD_KIND),metal)
$(error cloud.kind / CLOUD_KIND must be one of: aws, azure, gcp, metal)
endif


$(TF_DATA_DIR):
	@mkdir -p $@

init: $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
		$(STATE_BACKEND_CONFIG) \
		./$(CLOUD_KIND)

plan:
	$(terraform) plan $(TF_CLI_ARGS) -refresh=true -module-depth=-1 -out=$(TFPLAN) ./$(CLOUD_KIND)

refresh:
	$(terraform) refresh $(TF_CLI_ARGS) ./$(CLOUD_KIND)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)
	@echo

install:
	$(kubectl) apply -f kubernetes/namespace.yaml
	$(kubectl) apply -f kubernetes/grpc-client-secret.yaml
	$(kubectl) apply -f kubernetes/grpc-server-secret.yaml

	$(kubectl) apply -f kubernetes/crd/oidc.yaml
	$(kubectl) apply -f kubernetes/crd/authcodes.yaml
	$(kubectl) apply -f kubernetes/crd/authrequests.yaml
	$(kubectl) apply -f kubernetes/crd/connectors.yaml
	$(kubectl) apply -f kubernetes/crd/oauth2clients.yaml
	$(kubectl) apply -f kubernetes/crd/offlinesessionses.yaml
	$(kubectl) apply -f kubernetes/crd/passwords.yaml
	$(kubectl) apply -f kubernetes/crd/refreshtokens.yaml
	$(kubectl) apply -f kubernetes/crd/signingkeies.yaml

	$(kubectl) apply -f kubernetes/dex-rbac.yaml
	$(kubectl) get configmap dex || $(kubectl) apply -f kubernetes/configmap.yaml
	$(kubectl) apply -f kubernetes/deployment.yaml
	$(kubectl) apply -f kubernetes/service.yaml
	$(kubectl) apply -f kubernetes/service-api.yaml
	$(kubectl) apply -f kubernetes/$(INGRESS).yaml
	$(kubectl) apply -f kubernetes/auth-operator.yaml

undeploy: uninstall

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

uninstall:
	-$(kubectl) delete -f kubernetes/auth_v1alpha1_oidc.yaml
	-$(kubectl) delete -f kubernetes/auth-operator.yaml
	-$(kubectl) delete -f kubernetes/$(INGRESS).yaml
	-$(kubectl) delete -f kubernetes/service.yaml
	-$(kubectl) delete -f kubernetes/service-api.yaml
	-$(kubectl) delete -f kubernetes/deployment.yaml
	-$(kubectl) delete -f kubernetes/dex-rbac.yaml
	-$(kubectl) delete -f kubernetes/grpc-client-secret.yaml
	-$(kubectl) delete -f kubernetes/grpc-server-secret.yaml
	-$(kubectl) delete -f kubernetes/configmap.yaml

clean:
	rm -rf $(TF_DATA_DIR)

-include ../Mk/phonies
.IGNORE: undeploy
