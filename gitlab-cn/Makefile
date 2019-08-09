.DEFAULT_GOAL := deploy

COMPONENT_NAME   ?= gitlab-cn
HELM_CHART   	 ?= gitlab
HELM_PROJECT     ?= gitlab
DOMAIN_NAME      ?= dev.kubernetes.delivery
NAMESPACE 	 ?= gitlab
CHART_VERSION    ?= 1.7.5 
CLOUD_KIND   	 ?= aws
HELM_REPO        ?= https://charts.gitlab.io/

export HELM_HOME           ?= $(shell pwd)/.helm

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init fetch purge install output

init:
	@mkdir -p $(HELM_HOME) charts
	$(helm) init --client-only --upgrade
	$(helm) repo add gitlab $(HELM_REPO)
	$(helm) repo update

fetch:
	$(helm) fetch \
	  --destination charts \
	  --untar $(HELM_PROJECT)/$(HELM_CHART) \
	  --version $(CHART_VERSION)

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
	  $(kubectl) -n $(NAMESPACE) delete secret --all && \
	  $(helm) delete --purge $(COMPONENT_NAME) || exit 0

install:
	-$(kubectl) create namespace $(NAMESPACE)
	-$(kubectl) create -f oidc-crd.yaml
	-$(kubectl) create secret generic gitlab-dex-oicd --from-file=provider=gitlab-dex-provider.yaml
	-scripts/create_minio_secret.sh
	$(MAKE) -C $(CLOUD_KIND) $@
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
	  $(helm) install charts/$(notdir $(HELM_CHART)) \
	  --timeout 600 \
	  --name $(COMPONENT_NAME) \
	  --namespace $(NAMESPACE) \
	  --replace \
	  --wait \
	  --values values.yaml \
	  --version $(CHART_VERSION)
	$(MAKE) -C $(CLOUD_KIND) dns
	scripts/create_bot_account.sh
	scripts/create_minio_buckets.sh

undeploy: init
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
	  $(helm) delete --purge $(COMPONENT_NAME) || exit 0
	-$(kubectl) delete secret generic gitlab-dex-oicd
	-$(kubectl) delete -f oidc-crd.yaml | true
	

clean:
	rm -rf $(HELM_HOME) $(notdir $(HELM_CHART))

-include ../Mk/phonies
