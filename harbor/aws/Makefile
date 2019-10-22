.DEFAULT_GOAL := deploy

export DOMAIN_NAME    ?= dev.kubernetes.delivery
export COMPONENT_NAME ?= harbor
export NAMESPACE      ?= harbor
export PULL_SECRET    ?= $(COMPONENT_NAME)-pull-secret
export HELM_HOME      ?= $(shell pwd)/.helm

TLS_KIND              ?= letsencrypt

# storage kind: {s3, local}
STORAGE_KIND          ?= s3
CHART_VERSION         := 71b28b46fbb87a51bedc7d405f74167e9ee25143 # Apr 4, 2019  Merge pull request #183 from paulczar/gce-ingress
CHART_ORIGIN          := https://github.com/goharbor/harbor-helm.git
CHART_DIR             := $(HELM_HOME)/$(COMPONENT_NAME)

helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
git     ?= git -C $(CHART_DIR)


deploy: clean init namespace fetch install $(TLS_KIND) output

undeploy: undeploy-$(TLS_KIND) init delete clean
	- $(kubectl) delete pvc -l 'app=harbor,release=$(COMPONENT_NAME)'

$(TLS_KIND):
	$(MAKE) -C $(TLS_KIND) deploy
.PHONY: $(TLS_KIND)

undeploy-$(TLS_KIND):
	$(MAKE) -C $(TLS_KIND) undeploy

init: $(HELM_HOME)
	$(helm) init --client-only --upgrade --wait

patch:
	patch $(CHART_DIR)/templates/ingress/ingress.yaml ../harbor-ingress.patch

fetch: $(CHART_DIR)
	- $(git) init
	$(git) remote add origin $(CHART_ORIGIN)
	$(git) fetch
	$(git) reset --hard $(CHART_VERSION)

install: patch
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm)	install $(CHART_DIR) \
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
	@ echo harbor_host = $(COMPONENT_NAME).svc.$(DOMAIN_NAME)
	@ echo harbor_repo = $(COMPONENT_NAME).svc.$(DOMAIN_NAME)/library
	@ echo harbor_url = https://$(COMPONENT_NAME).svc.$(DOMAIN_NAME)
else
	@ echo harbor_host = $(COMPONENT_NAME).$(INGRESS_FQDN)
	@ echo harbor_repo = $(COMPONENT_NAME).$(INGRESS_FQDN)/library
	@ echo harbor_url = https://$(COMPONENT_NAME).$(INGRESS_FQDN)
endif
	@ echo

namespace:
	- $(kubectl) create namespace $(NAMESPACE)

$(HELM_HOME) $(CHART_DIR):
	mkdir -p $@

delete:
	- $(helm) delete --purge $(COMPONENT_NAME)

clean:
	rm -rf $(HELM_HOME)

-include ../../Mk/phonies
