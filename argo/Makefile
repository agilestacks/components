.DEFAULT_GOAL := deploy

DOMAIN_NAME      ?= dev.stacks.delivery
STATE_BUCKET     ?= terraform.agilestacks.com
STATE_REGION     ?= us-east-1
export TF_OPTS            ?= -no-color
export TF_UPDATE          ?= -update
export TF_DATA_DIR        ?= .terraform
export TF_VAR_component   ?= argo
export TF_VAR_namespace   ?= argoproj

ENDPOINT     ?= localhost:9000
SECRET_NAME  ?= minio
IMAGE_PREFIX := agilestacks/argo-
REPO_TYPE := minio

# export SECRET_NAME        ?= argo-repo-$(TF_VAR_component)

# https://github.com/hashicorp/terraform/issues/14847
unexport TF_CLI_ARGS

export HELM_HOME ?= $(shell pwd)/.helm
CHART_VERSION ?= 0.1.1

helm ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(TF_VAR_namespace)"

$(HELM_HOME):
	mkdir -p "$@"

rbac:
	$(kubectl) apply -f rbac.yaml
.PHONY: rbac

namespace:
	- $(kubectl) create namespace $(TF_VAR_namespace)
.PHONY: namespace

init: $(HELM_HOME)
	$(helm) init --client-only --upgrade --wait
	$(helm) repo add argo https://argoproj.github.io/argo-helm/
.PHONY: init

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

deploy: init namespace rbac install
ifeq ($(REPO_TYPE),s3)
	$(MAKE) -C s3 $@
else
	$(MAKE) -C minio $@
endif
	$(kubectl) apply -f ingress.yaml
.PHONY: deploy

undeploy: init
	$(helm) list -q | grep -E '^$(TF_VAR_component)$$' && \
		$(helm) delete --purge $(TF_VAR_component) || exit 0
ifeq ($(REPO_TYPE),s3)
	$(MAKE) -C s3 $@
else
	$(MAKE) -C minio $@
endif
.PHONY: undeploy

clean:
	rm -rf $(HELM_HOME)

output:
ifeq ($(REPO_TYPE),s3)
	$(MAKE) -C s3 $@
else
	$(MAKE) -C minio $@
endif
	@ echo
.PHONY: tf_output
