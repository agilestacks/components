SHELL := /bin/bash
.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= k8s-openshift
OPENSHIFT_TOKEN ?= must-be-set
API_ENDPOINT ?= must-be-set
DOMAIN_NAME ?= must-be-set
ASI_ACCOUNT ?= asi
ASI_ROLE ?= cluster-admin
ASI_SCC ?= agilestacks-scc

STATE_BUCKET   ?= terraform.agilestacks.com
STATE_REGION   ?= us-east-1

NAME           := $(shell echo $(DOMAIN_NAME) | cut -d. -f1)
BASE_DOMAIN    := $(shell echo $(DOMAIN_NAME) | cut -d. -f2-)
API_ENDPOINT   ?=
API_FQDN     := $(shell echo $(API_ENDPOINT) | cut -d: -f1)
API_PORT       := $(shell echo $(API_ENDPOINT) | cut -d: -f2)

$(if $(API_PORT),,API_PORT:=443)

export AWS_DEFAULT_REGION ?= us-east-2

export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(DOMAIN_NAME)-$(COMPONENT_NAME)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log
export TF_VAR_name        := $(NAME)
export TF_VAR_base_domain := $(BASE_DOMAIN)
export TF_VAR_api_fqdn      := $(API_FQDN)

terraform   ?= terraform-v0.11
TF_CLI_ARGS ?= -no-color -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan
oc ?= oc -n default

DISCOVERY_KUBE_CTX ?=
ifneq (,$(CA_CERT))
$(shell echo -e "$(CA_CERT)" > ca_cert.pem)
CA := --certificate-authority=ca_cert.pem
endif

account:
	$(oc) login $(API_ENDPOINT) --token=$(OPENSHIFT_TOKEN) $(CA)
	@if $(oc) get serviceaccount $(ASI_ACCOUNT) ; then \
		echo "Service Account $(ASI_ACCOUNT) exists"; \
	else \
		echo "Creating a new service account for $(ASI_ACCOUNT)..."; \
		$(oc) create serviceaccount $(ASI_ACCOUNT); \
		echo "Assigning $(ASI_ACCOUNT) $(ASI_ROLE) role"; \
		$(oc) adm policy add-cluster-role-to-user $(ASI_ROLE) -z $(ASI_ACCOUNT); \
		echo "Creating $(ASI_SCC) Security Context Constraints (SCC)"; \
		$(oc) create -f $(ASI_SCC).yaml; \
		$(oc) adm policy add-scc-to-user $(ASI_SCC) -z $(ASI_ACCOUNT); \
		echo "All service accounts that are created by ASI components (in namespaces managed by ASI) should be added to $(ASI_SCC) SCC"; \
		$(oc) adm policy add-scc-to-group $(ASI_SCC) system:serviceaccounts:ingress; \
		$(oc) adm policy add-scc-to-group $(ASI_SCC) system:serviceaccounts:dex; \
		$(oc) adm policy add-scc-to-group $(ASI_SCC) system:serviceaccounts:cert-manager; \
		$(oc) adm policy add-scc-to-group $(ASI_SCC) system:serviceaccounts:harbor; \
		$(oc) adm policy add-scc-to-group $(ASI_SCC) system:serviceaccounts:istio-system; \
		$(oc) adm policy add-scc-to-group $(ASI_SCC) system:serviceaccounts:prometheus; \
		$(oc) adm policy add-scc-to-group $(ASI_SCC) system:serviceaccounts:postgresql; \
		$(oc) adm policy add-scc-to-group $(ASI_SCC) system:serviceaccounts:mongodb; \
		$(oc) adm policy add-scc-to-group $(ASI_SCC) system:serviceaccounts:redis; \
		$(oc) adm policy add-scc-to-group $(ASI_SCC) system:serviceaccounts:nats; \
		$(oc) adm policy add-scc-to-group $(ASI_SCC) system:serviceaccounts:monitoring; \
		$(oc) adm policy add-scc-to-group $(ASI_SCC) system:serviceaccounts:minio; \
		$(oc) adm policy add-scc-to-group $(ASI_SCC) system:serviceaccounts:logs; \
		$(oc) adm policy add-scc-to-group $(ASI_SCC) system:serviceaccounts:jenkins; \
		$(oc) adm policy add-scc-to-group $(ASI_SCC) system:serviceaccounts:automation-tasks; \
		$(oc) adm policy add-scc-to-group $(ASI_SCC) system:serviceaccounts:applications; \
		$(oc) adm policy add-scc-to-group $(ASI_SCC) system:serviceaccounts:gitlab; \
	fi

check:
	$(eval EXISTING_DOMAIN:=$(shell $(oc) $(DISCOVERY_KUBE_CTX) get stackinfo asi-metadata -o json | jq -r .spec.domainName))
	@if [ "$(EXISTING_DOMAIN)" != "" ] && [ "$(EXISTING_DOMAIN)" != "$(DOMAIN_NAME)" ]; then\
    echo "Error: This cluster has already been imported using domain name: $(EXISTING_DOMAIN)";\
		echo "Error: Change of the domain name is not supported. This deployment will fail...";\
		exit 1;\
  fi
.PHONY: check

patch:
	echo "Disable default storageclass (if exists)"
	-$(oc) patch storageclass gp2 -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "false"}}}'
	-$(oc) patch storageclass gp2 -p '{"metadata": {"annotations": {"storageclass.beta.kubernetes.io/is-default-class": "false"}}}'

storage:
	$(oc) apply -f storage-class.yaml
.PHONY: storage

token:
	$(eval SECRET=$(shell $(oc) get serviceaccount $(ASI_ACCOUNT) -o json | \
		jq '.secrets[] | select(.name | contains("token")).name'))
	$(eval TOKEN_BASE64=$(shell $(oc) get secret $(SECRET) -o json | \
		jq '.data.token'))
	$(eval TOKEN=$(shell openssl enc -A -base64 -d <<< $(TOKEN_BASE64)))

$(TF_DATA_DIR):
	@rm -rf $@ && mkdir -p $@

init: $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(DOMAIN_NAME)/k8s-openshift/$(COMPONENT_NAME)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"

plan:
	$(terraform) plan -var vpc_id=$(VPC_ID) $(TF_CLI_ARGS) -refresh=true -module-depth=-1 -out=$(TFPLAN)

refresh:
	$(terraform) refresh $(TF_CLI_ARGS)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)

vpc:
	CONTEXT=$(DISCOVERY_KUBE_CTX) ./vpc.sh | tee $(DOMAIN_NAME).log
	tr -d '\r' < $(DOMAIN_NAME).log > $(DOMAIN_NAME).clean.log
	@grep -E '^vpc =' $(DOMAIN_NAME).clean.log >/dev/null

vars: vpc
	$(eval export AWS_DEFAULT_REGION := $(shell grep -E '^region =' $(DOMAIN_NAME).clean.log | awk '{print $$3}'))
	$(eval VPC_ID := $(shell grep -E '^vpc =' $(DOMAIN_NAME).clean.log | awk '{print $$3}'))

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

output:
	@cat $(DOMAIN_NAME).clean.log
	@echo
	@echo Outputs:
	@echo
	@echo dns_name = $(NAME)
	@echo dns_base_domain = $(BASE_DOMAIN)
	@echo sa_token=$(TOKEN)
	@echo

deploy: account check patch storage token init vars plan apply output

undeploy: DISCOVERY_KUBE_CTX:=--context=$(DOMAIN_NAME)
undeploy: check init vars destroy apply
	-$(oc) --context=$(DOMAIN_NAME) delete -f $(ASI_SCC).yaml
	-$(oc) --context=$(DOMAIN_NAME) delete serviceaccount $(ASI_ACCOUNT)

-include ../Mk/phonies
