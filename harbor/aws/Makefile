.DEFAULT_GOAL := deploy

export DOMAIN_NAME    ?= dev.kubernetes.delivery
export COMPONENT_NAME ?= harbor
export NAMESPACE      ?= harbor
export PULL_SECRET    ?= $(COMPONENT_NAME)-pull-secret
export HELM_HOME      ?= $(shell pwd)/.helm

TLS_KIND              ?= letsencrypt
STORAGE_KIND          ?= s3
# STORAGE_KIND          := local
CHART_VERSION         := master
# CHART_VERSION         := 1.0.0
CHART_ORIGIN          := https://github.com/goharbor/harbor-helm.git

helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
git     ?= git


deploy: clean init namespace storage-class fetch install $(TLS_KIND) output

undeploy: undeploy-$(TLS_KIND) init delete clean
	- $(kubectl) delete pvc -l 'app=harbor,release=$(COMPONENT_NAME)'

$(TLS_KIND):
	$(MAKE) -C $(TLS_KIND) deploy
.PHONY: $(TLS_KIND)

undeploy-$(TLS_KIND):
	$(MAKE) -C $(TLS_KIND) undeploy

storage-class:
	$(kubectl) apply -f storage-class.yaml

init: $(HELM_HOME)
	$(helm) init --client-only --upgrade --wait

fetch:
	$(git) clone --depth 1 -b $(CHART_VERSION) $(CHART_ORIGIN) $(HELM_HOME)/harbor

install:
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm)	install $(HELM_HOME)/harbor \
		    --name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--wait \
			--version $(CHART_VERSION) \
			--values values.yaml \
			--values $(TLS_KIND)/values.yaml \
			--values $(STORAGE_KIND)/values.yaml \
			--set "harborAdminPassword=$$ADMIN_PASSWORD" $(HELM_ARGS) \

output:
	@ echo
	@ echo Outputs:
	@ echo pull_secret = $(PULL_SECRET)
ifeq ("$(TLS_KIND)","acm")
	@ echo harbor_url = https://$(COMPONENT_NAME).svc.$(DOMAIN_NAME)
else
	@ echo harbor_url = https://$(COMPONENT_NAME).$(INGRESS_FQDN)
endif
	@ echo

namespace:
	- $(kubectl) create namespace $(NAMESPACE)

$(HELM_HOME):
	mkdir -p $@

delete:
	- $(helm) delete --purge $(COMPONENT_NAME)

clean:
	rm -rf $(HELM_HOME)


-include ../../Mk/phonies
