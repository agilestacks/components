.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export TF_VAR_namespace    ?= nginx-ingress
export TF_VAR_component    ?= nginxing
export TF_VAR_domain_name  ?= dev.kubernetes.delivery

CLOUD_KIND ?= aws
CHART_VERSION ?= 0.11.1
CHART ?= stable/nginx-ingress
STATE_BUCKET ?= terraform.agilestacks.com
STATE_REGION ?= us-east-1
helm ?= helm --kube-context="$(TF_VAR_domain_name)" --tiller-namespace="kube-system"
terraform ?= terraform

deploy: clean init fetch install get plan apply output
.PHONY: deploy

init:
	@mkdir -p $(HELM_HOME)
	$(helm) init --client-only --upgrade --wait
	@mkdir -p charts
	@mkdir -p .terraform
	$(terraform) init -get=true $(TF_CMD_OPTS) -force-copy  \
		-backend=true -input=false \
		-backend-config="bucket=$(STATE_BUCKET)" \
		-backend-config="region=$(STATE_REGION)" \
		-backend-config="key=$(TF_VAR_domain_name)/nginxing/$(TF_VAR_component)/terraform.tfstate" \
		-backend-config="profile=$(AWS_PROFILE)"

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
			--values values.yaml \
			--version $(CHART_VERSION)
.PHONY: install

get:
	$(terraform) get $(TF_UPDATE)
.PHONY: get

plan:
	$(terraform) plan $(TF_OPTS) -refresh=true -module-depth=-1 -out=.terraform/$(TF_VAR_domain_name).tfplan
..PHONY: plan

apply:
	$(terraform) apply $(TF_OPTS) -Xshadow=false .terraform/$(TF_VAR_domain_name).tfplan
.PHONY: apply

undeploy: init
	$(MAKE) plan TF_OPTS="$(TF_OPTS) -destroy"
	# roll forward on error for undeploy
	-$(MAKE) apply

	$(helm) list -q | grep -E '^$(TF_VAR_component)$$' && \
		$(helm) delete --purge $(TF_VAR_component) || exit 0
.PHONY: undeploy

clean:
	rm -rf $(HELM_HOME)
	rm -rf charts
	rm -rf .terraform/modules
	rm -rf .terraform/plugins

output:
	@echo Outputs:
#	@echo ingress_fqdn=$(URL_PREFIX).$(DOMAIN_NAME)
.PHONY: output