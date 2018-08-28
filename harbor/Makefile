.DEFAULT_GOAL := deploy

DOMAIN_NAME    ?= dev.stacks.delivery
STATE_BUCKET   ?= terraform.agilestacks.com
NAMESPACE      ?= harbor
COMPONENT 	   ?= harbor

export TF_OPTS            ?= -no-color
export TF_UPDATE          ?= -update
export TF_VAR_component   ?= argo
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
.PHONY: deploy

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
	- $(kubectl) delete secret argo-repo-$(TF_VAR_component)
.PHONY: undeploy

