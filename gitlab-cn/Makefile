.DEFAULT_GOAL := deploy

COMPONENT_NAME   ?= gitlab-cn
HELM_CHART   	 ?= gitlab
HELM_PROJECT     ?= gitlab
DOMAIN_NAME      ?= dev.kubernetes.delivery
NAMESPACE 	 ?= gitlab
CHART_VERSION    ?= 1.7.5 
CLOUD_TYPE   	 ?= aws
HELM_REPO        ?= https://charts.gitlab.io/

export HELM_HOME           ?= $(shell pwd)/.helm

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init fetch purge install output

init:
	@mkdir -p $(HELM_HOME) charts
	$(helm) init --client-only --upgrade
	$(helm)helm repo add gitlab $(HELM_REPO)

fetch:
	$(helm) fetch \
	  --destination charts \
	  --untar $(HELM_PROJECT)/$(HELM_CHART) \
	  --version $(CHART_VERSION)

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
	  $(helm) delete --purge $(COMPONENT_NAME) || exit 0

install:
	-$(kubectl) create namespace $(NAMESPACE)
	scripts/create_minio_secret.sh
	$(MAKE) -C $(CLOUD_TYPE) $@
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
	  $(helm) upgrade --install $(notdir $(HELM_CHART)) \
	  --timeout 600
	  --name $(COMPONENT_NAME) \
	  --name-template $(COMPONENT_NAME) \
	  --namespace $(NAMESPACE) \
	  --replace \
	  --wait \
	  --values values.yaml \
	  --version $(CHART_VERSION)

undeploy: init
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
	  $(helm) delete --purge $(COMPONENT_NAME) || exit 0
	$(MAKE) -C $(CLOUD_TYPE) $@

clean:
	rm -rf $(HELM_HOME) $(notdir $(HELM_CHART))

-include ../Mk/phonies
