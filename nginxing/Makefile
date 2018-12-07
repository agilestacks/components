.DEFAULT_GOAL := deploy

CHART_VERSION ?= 0.11.1
CHART         ?= stable/nginx-ingress

STATE_BUCKET ?= terraform.agilestacks.com
STATE_REGION ?= us-east-1

export AWS_DEFAULT_REGION ?= us-east-2
export HELM_HOME          ?= $(shell pwd)/.helm

export TF_VAR_component   ?= nginxing
export TF_VAR_domain_name ?= dev.kubernetes.delivery
export TF_VAR_namespace   ?= nginx-ingress

export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(TF_VAR_domain_name)-$(TF_VAR_component)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log

helm        ?= helm --kube-context="$(TF_VAR_domain_name)" --tiller-namespace="kube-system"
terraform   ?= terraform-v0.11
TF_CLI_ARGS ?= -no-color -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan

deploy: clean init fetch purge install plan apply

$(TF_DATA_DIR):
	@rm -rf $@ && mkdir -p $@

init: $(TF_DATA_DIR)
	@mkdir -p $(HELM_HOME) charts
	$(helm) init --client-only --upgrade --wait
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(TF_VAR_domain_name)/nginxing/$(TF_VAR_component)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"

fetch:
	$(helm) fetch \
		--destination charts \
		--untar $(CHART) \
		--version $(CHART_VERSION)

purge:
	$(helm) list --deleted --failed -q --namespace $(TF_VAR_namespace) | grep -E '^$(TF_VAR_component)$$' && \
		$(helm) delete --purge $(TF_VAR_component) || exit 0

install:
	$(helm) list -q --namespace $(TF_VAR_namespace) | grep -E '^$(TF_VAR_component)$$' || \
		$(helm) install charts/$(notdir $(CHART)) \
			--name $(TF_VAR_component) \
			--namespace $(TF_VAR_namespace) \
			--replace \
			--wait \
			--values values.yaml \
			--version $(CHART_VERSION)

plan:
	$(terraform) plan $(TF_CLI_ARGS) -refresh=true -module-depth=-1 -out=$(TFPLAN)

refresh:
	$(terraform) refresh $(TF_CLI_ARGS)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)

output:
	@$(terraform) output -no-color

undeploy: init destroy apply uninstall

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

uninstall:
	$(helm) list -q --namespace $(TF_VAR_namespace) | grep -E '^$(TF_VAR_component)$$' && \
		$(helm) delete --purge $(TF_VAR_component) || exit 0

clean:
	rm -rf $(HELM_HOME) charts

-include ../Mk/phonies
