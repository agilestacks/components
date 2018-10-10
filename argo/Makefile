.DEFAULT_GOAL := deploy

DOMAIN_NAME      ?= dev.stacks.delivery
STATE_BUCKET     ?= terraform.agilestacks.com
STATE_REGION     ?= us-east-1

ENDPOINT     ?=
SECRET_NAME  ?= minio
IMAGE_PREFIX := agilestacks/argo-
REPO_TYPE 	 := minio

export TF_VAR_component   ?= argo
export TF_VAR_namespace   ?= argoproj

HELM_ARGS :=

# export SECRET_NAME        ?= argo-repo-$(TF_VAR_component)

# https://github.com/hashicorp/terraform/issues/14847
unexport TF_CLI_ARGS

export HELM_HOME ?= $(CURDIR)/.helm
CHART ?= argo/argo
CHART_VERSION ?= 2.1.1

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
	- $(helm) repo update
	- $(helm) search argo
.PHONY: init

fetch:
	$(helm) fetch \
		--destination charts \
		--untar $(CHART) \
		--version "$(CHART_VERSION)"
.PHONY: fetch

install: fetch
ifeq ($(REPO_TYPE),s3)
	$(eval ENDPOINT := $(shell $(MAKE) -C s3 output TF_OPTS="-json" | jq -crM '.endpoint.value'))
endif
ifeq ($(ENDPOINT),)
	$(eval HELM_ARGS += --set "artifactRepository.defaultBucket.enabled=false")
else
	$(eval HELM_ARGS += --set "artifactRepository.defaultBucket.enabled=true")
	$(eval HELM_ARGS += --set "artifactRepository.s3.endpoint=$(ENDPOINT)")
endif
	$(helm) list -q | grep -E '^$(TF_VAR_component)$$' || \
		$(helm) install argo/argo \
			--name $(TF_VAR_component) \
			--namespace $(TF_VAR_namespace) \
			--replace \
			--wait \
			--values values.yaml \
			$(HELM_ARGS) \
			--version '$(CHART_VERSION)'
.PHONY: install

deploy: init namespace rbac install
	$(MAKE) -C $(REPO_TYPE) $@
	$(MAKE) -C events $@
	$(kubectl) apply -f ingress.yaml
.PHONY: deploy

undeploy: init
	$(helm) list -q | grep -E '^$(TF_VAR_component)$$' && \
		$(helm) delete --purge $(TF_VAR_component) || exit 0
	$(MAKE) -C $(REPO_TYPE) $@
	$(MAKE) -C events $@
.PHONY: undeploy

clean:
	rm -rf $(HELM_HOME)
	rm -rf charts

output:
	$(MAKE) -C $(REPO_TYPE) $@
	@ echo
.PHONY: tf_output
