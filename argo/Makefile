.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= argo
DOMAIN_NAME    ?= dev.stacks.delivery
STATE_BUCKET   ?= terraform.agilestacks.com
STATE_REGION   ?= us-east-1
NAMESPACE      ?= argoproj

export TF_OPTS            ?= -no-color
export TF_UPDATE          ?= -update
export TF_VAR_name        := $(COMPONENT_NAME)
export TF_CLI_ARGS        ?=
export TF_DATA_DIR        ?= .terraform

export HELM_HOME ?= $(shell pwd)/.helm
CHART_VERSION ?= 0.1.1

terraform ?= terraform-v0.11
helm ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

$(TF_DATA_DIR):
	mkdir -p "$@"

$(HELM_HOME):
	mkdir -p "$@"

namespace:
	- $(kubectl) create namespace $(NAMESPACE)

init: $(TF_DATA_DIR) $(HELM_HOME) namespace
	$(helm) init --client-only --upgrade --wait
	$(helm) repo add argo https://argoproj.github.io/argo-helm/
	$(terraform) init -get=true $(TF_CMD_OPTS) -force-copy \
        -backend=true -input=false -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(DOMAIN_NAME)/argo/$(COMPONENT_NAME)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"
.PHONY: init

deploy:
	$(MAKE) init plan
	$(MAKE) apply || \
	$(MAKE) import plan apply
	$(kubectl) apply -f rbac.yaml
	$(kubectl) apply -f ingress.yaml
	$(MAKE) fetch install

	$(kubectl) apply -f events/argo-events-sa.yaml
	$(kubectl) apply -f events/argo-events-cluster-roles.yaml
	$(kubectl) apply -f events/sensor-crd.yaml
	$(kubectl) apply -f events/sensor-controller-configmap.yaml
	$(kubectl) apply -f events/sensor-controller-deployment.yaml
	$(kubectl) apply -f events/webhook.yaml
.PHONY: deploy

fetch: $(HELM_HOME) $(TF_DATA_DIR)
	$(helm) repo update
	$(helm) fetch \
		--destination charts \
		--untar argo/argo \
		--version '$(CHART_VERSION)'
.PHONY: fetch

install:
	$(eval ACCESS_KEY_ID := $(shell $(MAKE) output TF_CLI_ARGS="-json" | jq -crM '.access_key_id.value'))
	$(eval SECRET_KEY_ID := $(shell $(MAKE) output TF_CLI_ARGS="-json" | jq -crM '.secret_access_key.value'))

	$(helm) list -q | grep -E '^$(TF_VAR_component)$$' || \
		$(helm) install charts/$(notdir $(CHART)) \
			--name $(TF_VAR_component) \
			--namespace $(NAMESPACE) \
			--replace \
			--wait \
			--values values.yaml \
			--set accesskey=$(ACCESS_KEY_ID),secretkey=$(SECRET_KEY_ID) \
			--version '$(CHART_VERSION)'
			$(kubectl) get services -o wide | grep argo-
.PHONY: install

undeploy: init
	$(helm) list -q | grep -E '^$(TF_VAR_component)$$' && \
		$(helm) delete --purge $(TF_VAR_component) || exit 0

	$(MAKE) plan TF_CLI_ARGS="-destroy"
	$(MAKE) apply
	- $(kubectl) delete -f ingress.yaml
	- $(kubectl) delete -f rbac.yaml
	# cleaning some garbage left by helm chart
	- $(kubectl) delete job argo-apply-workflow-crd
	- $(kubectl) delete job/argo-events-apply-sensor-crd

	- $(kubectl) delete -f events/webhook.yaml
	- $(kubectl) delete -f events/sensor-controller-deployment.yaml
	- $(kubectl) delete -f events/sensor-controller-configmap.yaml
	- $(kubectl) delete -f events/sensor-crd.yaml
	- $(kubectl) delete -f events/argo-events-cluster-roles.yaml
	- $(kubectl) delete -f events/argo-events-sa.yaml
.PHONY: undeploy

clean:
	rm -rf $(HELM_HOME)
	rm -rf $(TF_DATA_DIR)

import:
	- $(terraform) import aws_iam_user.main $(TF_VAR_component)
.PHONY: import

plan:
	$(terraform) plan -refresh=true -module-depth=-1 -out=.terraform/terraform.tfplan
.PHONY: plan

refresh:
	$(terraform) refresh
.PHONY: refresh

apply:
	$(terraform) apply -auto-approve .terraform/terraform.tfplan
.PHONY: apply

output:
	@ $(terraform) output
.PHONY: output
