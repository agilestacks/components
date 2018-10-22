.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export TF_VAR_namespace    ?= ingress
export TF_VAR_component    ?= traefik
export TF_VAR_domain_name  ?= dev.kubernetes.delivery

CLOUD_KIND          ?= aws
ACM_CERTIFICATE_ARN ?=
CHART_VERSION       ?= 1.52.1
CHART               ?= stable/traefik

STATE_BUCKET ?= terraform.agilestacks.com
STATE_REGION ?= us-east-1

helm ?= helm --kube-context="$(TF_VAR_domain_name)" --tiller-namespace="kube-system"
terraform ?= terraform-v0.11

ifneq (,$(ACM_CERTIFICATE_ARN))
	VALUES_FILE=values-acm.yaml
	PROTOCOL=https
else
	VALUES_FILE=values.yaml
	PROTOCOL=http
endif

deploy: clean init fetch purge install get plan output apply

ifneq (,$(filter $(CLOUD_KIND),aws hybrid))
STATE_BACKEND_CONFIG := -backend-config="key=$(TF_VAR_domain_name)/traefik/$(TF_VAR_component)/terraform.tfstate" \
				-backend-config="profile=$(AWS_PROFILE)"
else ifeq ($(CLOUD_KIND),gcp)
STATE_BACKEND_CONFIG := -backend-config="prefix=$(TF_VAR_domain_name)/traefik/$(TF_VAR_component)" \
				-backend-config="credentials=$(GOOGLE_APPLICATION_CREDENTIALS)"
else
	$(error cloud.kind / CLOUD_KIND must be one of: aws, gcp, hybrid)
endif

init:
	@mkdir -p $(HELM_HOME) charts .terraform
	$(helm) init --client-only --upgrade --wait
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

purge:
	if $(helm) list --deleted --failed -q --namespace $(TF_VAR_namespace) | grep -E '^$(TF_VAR_component)$$'; then \
		echo Deleting $(TF_VAR_component); \
		$(helm) delete --purge $(TF_VAR_component); \
	fi
.PHONY: purge

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
.PHONY: install

upgrade:
	$(helm) upgrade $(TF_VAR_component) charts/$(notdir $(CHART)) \
		--namespace $(TF_VAR_namespace) \
		--wait \
		--values $(VALUES_FILE) \
		--version $(CHART_VERSION)
.PHONY: upgrade

get:
	$(terraform) get $(TF_UPDATE) ./$(CLOUD_KIND)
.PHONY: get

plan:
	$(terraform) plan $(TF_OPTS) -refresh=true -module-depth=-1 -out=.terraform/terraform.tfplan ./$(CLOUD_KIND)
.PHONY: plan

apply:
	$(terraform) apply $(TF_OPTS) -Xshadow=false .terraform/terraform.tfplan
	@echo
.PHONY: apply

undeploy: init destroy apply uninstall

destroy: TF_OPTS:=-destroy
destroy: plan

uninstall:
	$(helm) list -q --namespace $(TF_VAR_namespace) | grep -E '^$(TF_VAR_component)$$' && \
		$(helm) delete --purge $(TF_VAR_component)
.PHONY: undeploy

clean:
	rm -rf $(HELM_HOME) charts .terraform/modules .terraform/plugins
.PHONY: clean

output:
	@echo
	@echo Outputs:
	@echo ingress_protocol = $(PROTOCOL)
	@echo
.PHONY: output
