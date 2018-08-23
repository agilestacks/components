.DEFAULT_GOAL := deploy

DOMAIN_NAME      ?= dev.stacks.delivery
STATE_BUCKET     ?= terraform.agilestacks.com
STATE_REGION     ?= us-east-1
export TF_OPTS            ?= -no-color
export TF_UPDATE          ?= -update
export TF_DATA_DIR        ?= .terraform
export TF_VAR_component   ?= argo
export TF_VAR_namespace   ?= argoproj
export KUBE_CTX           := $(DOMAIN_NAME)

# export SECRET_NAME        ?= argo-repo-$(TF_VAR_component)

# https://github.com/hashicorp/terraform/issues/14847
unexport TF_CLI_ARGS

export HELM_HOME ?= $(shell pwd)/.helm
CHART_VERSION ?= 0.1.1

terraform ?= terraform-v0.11
helm ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(TF_VAR_namespace)"


$(TF_DATA_DIR):
	mkdir -p "$@"

$(HELM_HOME):
	mkdir -p "$@"

namespace:
	- $(kubectl) create namespace $(TF_VAR_namespace)
.PHONY: namespace

init: $(TF_DATA_DIR) $(HELM_HOME) namespace
	$(helm) init --client-only --upgrade --wait
	$(helm) repo add argo https://argoproj.github.io/argo-helm/
	$(terraform) init $(TF_OPTS) \
        -get=true -force-copy \
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

	@ echo
	$(kubectl) apply -f rbac.yaml
	$(kubectl) apply -f ingress.yaml
	$(MAKE) fetch install

	$(kubectl) apply -f events/argo-events-sa.yaml
	$(kubectl) apply -f events/argo-events-cluster-roles.yaml
	$(kubectl) apply -f events/sensor-crd.yaml
	$(kubectl) apply -f events/sensor-controller-configmap.yaml
	$(kubectl) apply -f events/sensor-controller-deployment.yaml
	$(kubectl) apply -f events/webhook.yaml
	$(kubectl) apply -f events/artifact.yaml
.PHONY: deploy

fetch: $(HELM_HOME) $(TF_DATA_DIR)
	$(helm) repo update
	$(helm) fetch \
		--destination charts \
		--untar argo/argo \
		--version '$(CHART_VERSION)'
.PHONY: fetch

install:
	$(eval ENDPOINT := $(shell $(MAKE) output TF_OPTS="-json" | jq -crM '.endpoint.value'))
	@ echo Running: helm install...
	@ $(helm) list -q | grep -E '^$(TF_VAR_component)$$' || \
		$(helm) install charts/$(notdir $(CHART)) \
			--name $(TF_VAR_component) \
			--namespace $(TF_VAR_namespace) \
			--replace \
			--wait \
			--values values.yaml \
			--set "artifactRepository.s3.endpoint=$(ENDPOINT)" \
			--version '$(CHART_VERSION)'
	$(kubectl) get services -o wide | grep argo-
.PHONY: install

undeploy: init
	$(helm) list -q | grep -E '^$(TF_VAR_component)$$' && \
		$(helm) delete --purge $(TF_VAR_component) || exit 0

	$(MAKE) plan TF_OPTS="-destroy -no-color"
	$(MAKE) apply
	- $(kubectl) delete -f ingress.yaml
	- $(kubectl) delete -f rbac.yaml
	# cleaning some garbage left by helm chart
	- $(kubectl) delete job argo-apply-workflow-crd
	- $(kubectl) delete job/argo-events-apply-sensor-crd

	- $(kubectl) delete -f events/artifact.yaml
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
	- $(terraform) import $(TF_OPTS) module.user.aws_iam_user.main agilestacks-$(TF_VAR_component)
	- $(terraform) import $(TF_OPTS) kubernetes_secret.aws $(TF_VAR_namespace)/argo-repo-$(TF_VAR_component)
.PHONY: import

plan:
	$(terraform) plan $(TF_OPTS) -refresh=true -module-depth=-1 -out=.terraform/terraform.tfplan
.PHONY: plan

refresh:
	$(terraform) refresh $(TF_OPTS)
.PHONY: refresh

apply:
	$(terraform) apply $(TF_OPTS) -auto-approve .terraform/terraform.tfplan
.PHONY: apply

output:
	@ $(terraform) output $(TF_OPTS)
	@ echo
.PHONY: output
