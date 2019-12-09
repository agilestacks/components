.DEFAULT_GOAL := deploy

COMPONENT_NAME     ?= traefik2
DOMAIN_NAME        ?= test.dev.superhub.io
NAMESPACE          ?= ingress
KUBECONFIG_CONTEXT ?= $(DOMAIN_NAME)

CLOUD_KIND ?= aws

STATE_BUCKET    ?= terraform.agilestacks.com
STATE_REGION    ?= us-east-1
STATE_CONTAINER ?= agilestacks

export AWS_DEFAULT_REGION ?= us-east-2

export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(DOMAIN_NAME)-$(COMPONENT_NAME)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log

kubectl   ?= kubectl --context="$(KUBECONFIG_CONTEXT)" --namespace="$(NAMESPACE)"
terraform ?= terraform-v0.11

TF_CLI_ARGS ?= -no-color -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan

export TF_VAR_component          ?= $(COMPONENT_NAME)
export TF_VAR_domain_name        ?= $(DOMAIN_NAME)
export TF_VAR_namespace          ?= $(NAMESPACE)
export TF_VAR_kubeconfig_context ?= $(KUBECONFIG_CONTEXT)

ifneq (,$(filter $(CLOUD_KIND),aws))
STATE_BACKEND_CONFIG := -backend-config="bucket=$(STATE_BUCKET)" \
        		-backend-config="region=$(STATE_REGION)" \
				-backend-config="key=$(DOMAIN_NAME)/$(COMPONENT_NAME)/terraform.tfstate" \
				-backend-config="profile=$(AWS_PROFILE)"
else
$(error cloud.kind / CLOUD_KIND must be one of: aws)
endif

ifneq (,$(filter cert-manager,$(HUB_PROVIDES)))
	PROTOCOL:=https
	PROVIDES:=tls-ingress
else
	PROTOCOL:=http
endif

deploy: clean init install plan apply output
undeploy: init destroy apply uninstall

$(TF_DATA_DIR):
	@mkdir -p $@

init: $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
		$(STATE_BACKEND_CONFIG) \
		./$(CLOUD_KIND)

install:
	$(kubectl) apply -f namespace.yaml
	$(kubectl) apply -f crds.yaml
	$(kubectl) apply -f rbac.yaml
	$(kubectl) apply -f configmap.yaml
	$(kubectl) apply -f acme-pvc.yaml
	$(kubectl) apply -f deployment.yaml
	$(kubectl) apply -f service.yaml
	$(kubectl) apply -f dashboard.yaml

uninstall:
	-$(kubectl) delete -f dashboard.yaml
	-$(kubectl) delete -f service.yaml
	-$(kubectl) delete -f deployment.yaml
	-$(kubectl) delete -f acme-pvc.yaml
	-$(kubectl) delete -f configmap.yaml
	-$(kubectl) delete -f rbac.yaml
	-$(kubectl) delete -f crds.yaml
	-$(kubectl) get crd -o name | grep -F traefik.containo.us | xargs $(kubectl) delete

plan:
	$(terraform) plan $(TF_CLI_ARGS) -refresh=true -module-depth=-1 -out=$(TFPLAN) ./$(CLOUD_KIND)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)
	@echo

output:
	@echo
	@echo Outputs:
	@echo ingress_protocol = $(PROTOCOL)
	@echo provides = $(PROVIDES)
	@echo

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

clean:
	rm -rf $(TF_DATA_DIR)

-include ../Mk/phonies
