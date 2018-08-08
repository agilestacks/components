.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export TF_VAR_namespace    ?= ingress
export TF_VAR_component    ?= traefik
export TF_VAR_domain_name  ?= dev.kubernetes.delivery

CLOUD_KIND ?= aws
ACM_CERTIFICATE_ARN ?= undefined
CHART_VERSION ?= 1.14.2
CHART ?= stable/traefik
STATE_BUCKET ?= terraform.agilestacks.com
STATE_REGION ?= us-east-1
helm ?= helm --kube-context="$(TF_VAR_domain_name)" --tiller-namespace="kube-system"
terraform ?= terraform-v0.11

ifeq ($(ACM_CERTIFICATE_ARN),undefined)
	VALUES_FILE=values.yaml
	PROTOCOL=http
else
	VALUES_FILE=values-acm.yaml
	PROTOCOL=https
endif

deploy: clean init fetch install get plan apply output
.PHONY: deploy

ifeq ($(CLOUD_KIND),aws)
STATE_BACKEND_CONFIG := -backend-config="key=$(TF_VAR_domain_name)/traefik/$(TF_VAR_component)/terraform.tfstate" \
				-backend-config="profile=$(AWS_PROFILE)"
else ifeq ($(CLOUD_KIND),gcp)
STATE_BACKEND_CONFIG := -backend-config="prefix=$(TF_VAR_domain_name)/traefik/$(TF_VAR_component)" \
				-backend-config="credentials=$(GOOGLE_APPLICATION_CREDENTIALS)"
else
	$(error cloud.kind / CLOUD_KIND must be one of: aws, gcp)
endif

init:
	@mkdir -p $(HELM_HOME)
	$(helm) init --client-only --upgrade --wait
	@mkdir -p charts
	@mkdir -p .terraform
	$(terraform) init $(TF_OPTS) \
		-get=true -reconfigure -force-copy  \
		-backend=true -input=false \
		-backend-config="bucket=$(STATE_BUCKET)" \
		-backend-config="region=$(STATE_REGION)" \
		$(STATE_BACKEND_CONFIG) \
		./$(CLOUD_KIND)
.PHONY: init

fetch:
	$(helm) fetch \
		--destination charts \
		--untar $(CHART) \
		--version $(CHART_VERSION)
.PHONY: fetch

install:
	$(helm) list -q | grep -E '^$(TF_VAR_component)$$' || \
		$(helm) install charts/$(notdir $(CHART)) \
			--name $(TF_VAR_component) \
			--namespace $(TF_VAR_namespace) \
			--replace \
			--wait \
			--values $(VALUES_FILE) \
			--version $(CHART_VERSION)
.PHONY: install

get:
	$(terraform) get $(TF_UPDATE) ./$(CLOUD_KIND)
.PHONY: get

plan:
	$(terraform) plan $(TF_OPTS) -refresh=true -module-depth=-1 -out=.terraform/terraform.tfplan ./$(CLOUD_KIND)
.PHONY: plan

apply:
	$(terraform) apply $(TF_OPTS) -Xshadow=false .terraform/terraform.tfplan
.PHONY: apply

undeploy: init
	- $(MAKE) plan TF_OPTS="$(TF_OPTS) -destroy"
	# roll forward on error for undeploy
	- $(MAKE) apply

	$(helm) list -q | grep -E '^$(TF_VAR_component)$$' && \
		$(helm) delete --purge $(TF_VAR_component) || exit 0
.PHONY: undeploy

clean:
	rm -rf $(HELM_HOME)
	rm -rf charts
	rm -rf .terraform/modules
	rm -rf .terraform/plugins

output:
	@echo
	@echo Outputs:
	@echo ingress_protocol = $(PROTOCOL)
	@echo
.PHONY: output
