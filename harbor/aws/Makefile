.DEFAULT_GOAL := deploy

export DOMAIN_NAME    ?= dev.kubernetes.delivery
export COMPONENT_NAME ?= harbor
export NAMESPACE      ?= harbor
export PULL_SECRET    ?= $(COMPONENT_NAME)-pull-secret
export HELM_HOME      ?= $(shell pwd)/.helm

TLS_KIND              ?= letsencrypt

# storage kind: {s3, local}
STORAGE_KIND          ?= s3
CHART_VERSION         := 8008f7d830282545a55e0340495c5ed3700dedf5	# Apr 4, 2019  Merge pull request #183 from paulczar/gce-ingress
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
	@echo fetching helm chart from $(CHART_VERSION) on $(CHART_ORIGIN)
	rm -rf mkdir -p $(HELM_HOME)/harbor
	mkdir -p $(HELM_HOME)/harbor
	cd $(HELM_HOME)/harbor && \
		$(git) init && \
		$(git) remote add origin $(CHART_ORIGIN) && \
		$(git) fetch --depth 1 origin $(CHART_VERSION) && \
		$(git) reset --hard FETCH_HEAD

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
