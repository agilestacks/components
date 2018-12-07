.DEFAULT_GOAL := deploy

export TF_VAR_component          ?= traefik
export TF_VAR_domain_name        ?= dev.kubernetes.delivery
export TF_VAR_namespace          ?= ingress
export TF_VAR_kubeconfig_context ?= $(TF_VAR_domain_name)

CLOUD_KIND          ?= aws
ACM_CERTIFICATE_ARN ?=
CHART_VERSION       ?= 1.52.1
CHART               ?= stable/traefik

STATE_BUCKET ?= terraform.agilestacks.com
STATE_REGION ?= us-east-1

export AWS_DEFAULT_REGION ?= us-east-2
export HELM_HOME          ?= $(shell pwd)/.helm

export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(TF_VAR_domain_name)-$(TF_VAR_component)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log

helm        ?= helm --kube-context="$(TF_VAR_kubeconfig_context)" --tiller-namespace="kube-system"
terraform   ?= terraform-v0.11
TF_CLI_ARGS ?= -no-color -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan

ifneq (,$(ACM_CERTIFICATE_ARN))
	VALUES_FILE=values-acm.yaml
	PROTOCOL=https
else
	VALUES_FILE=values.yaml
	PROTOCOL=http
endif

deploy: clean init fetch purge install plan output apply

ifneq (,$(filter $(CLOUD_KIND),aws hybrid))
STATE_BACKEND_CONFIG := -backend-config="key=$(TF_VAR_domain_name)/traefik/$(TF_VAR_component)/terraform.tfstate" \
				-backend-config="profile=$(AWS_PROFILE)"
else ifeq ($(CLOUD_KIND),gcp)
STATE_BACKEND_CONFIG := -backend-config="prefix=$(TF_VAR_domain_name)/traefik/$(TF_VAR_component)" \
				-backend-config="credentials=$(GOOGLE_APPLICATION_CREDENTIALS)"
else
	$(error cloud.kind / CLOUD_KIND must be one of: aws, gcp, hybrid)
endif

$(TF_DATA_DIR):
	@rm -rf $@ && mkdir -p $@

init: $(TF_DATA_DIR)
	@mkdir -p $(HELM_HOME) charts
	$(helm) init --client-only --upgrade --wait
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
		$(STATE_BACKEND_CONFIG) \
		./$(CLOUD_KIND)

fetch:
	$(helm) fetch \
		--destination charts \
		--untar $(CHART) \
		--version $(CHART_VERSION)

purge:
	$(helm) list --deleted --failed -q --namespace $(TF_VAR_namespace) | grep -E '^$(TF_VAR_component)$$' && \
		$(helm) delete --purge $(TF_VAR_component) || exit 0

install:
	if ! $(helm) list -q --namespace $(TF_VAR_namespace) | grep -E '^$(TF_VAR_component)$$'; then \
		$(helm) install charts/$(notdir $(CHART)) \
			--name $(TF_VAR_component) \
			--namespace $(TF_VAR_namespace) \
			--replace \
			--wait \
			--values $(VALUES_FILE) \
			--version $(CHART_VERSION); \
	else \
		$(MAKE) upgrade; \
	fi

upgrade:
	$(helm) upgrade $(TF_VAR_component) charts/$(notdir $(CHART)) \
		--namespace $(TF_VAR_namespace) \
		--wait \
		--values $(VALUES_FILE) \
		--version $(CHART_VERSION)

plan:
	$(terraform) plan $(TF_CLI_ARGS) -refresh=true -module-depth=-1 -out=$(TFPLAN) ./$(CLOUD_KIND)

refresh:
	$(terraform) refresh $(TF_CLI_ARGS) ./$(CLOUD_KIND)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)
	@echo

output:
	@echo
	@echo Outputs:
	@echo ingress_protocol = $(PROTOCOL)
	@echo

undeploy: init destroy apply uninstall

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

uninstall:
	$(helm) list -q --namespace $(TF_VAR_namespace) | grep -E '^$(TF_VAR_component)$$' && \
		$(helm) delete --purge $(TF_VAR_component)

clean:
	rm -rf $(HELM_HOME) charts $(TF_DATA_DIR)
