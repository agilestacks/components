.DEFAULT_GOAL := deploy

export DOMAIN_NAME    ?= dev.kubernetes.delivery
export COMPONENT_NAME ?= harbor
export NAMESPACE      ?= harbor
export PULL_SECRET    ?= $(COMPONENT_NAME)-pull-secret
export HELM_HOME      ?= $(shell pwd)/.helm

TLS_KIND              ?= letsencrypt
STORAGE_KIND          ?= s3
CHART_VERSION         ?= 1.0.0
CHART_ORIGIN          := https://github.com/goharbor/harbor-helm.git

helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
git     ?= git

deploy: clean init namespace storage-class fetch install pull-secret output

undeploy: init delete clean
	- $(MAKE) -C $(TLS_KIND) undeploy
	- $(kubectl) delete secret $(PULL_SECRET)

$(HELM_HOME):
	mkdir -p $@

namespace:
	- $(kubectl) create namespace $(NAMESPACE)

pull-secret: namespace
	@ echo "Creating pull secret $(PULL_SECRET) for $(INGRESS_FQDN)"
	- @ $(kubectl) create secret docker-registry $(PULL_SECRET) \
		--docker-server=$(INGRESS_FQDN) \
		--docker-username=$(ADMIN_USERNAME) \
		--docker-password=$(ADMIN_PASSWORD)

storage-class: 
	$(kubectl) apply -f storage-class.yaml

init: $(HELM_HOME)
	$(helm) init --client-only --upgrade --wait

fetch:
	$(git) clone --depth 1 -b $(CHART_VERSION) $(CHART_ORIGIN) $(HELM_HOME)/harbor
# 	$(helm) dependency update $(HELM_HOME)/harbor	

install:
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm)	install $(HELM_HOME)/harbor \
		    --name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--wait \
			--version $(CHART_VERSION) \
			--values values.yaml \
			--values $(TLS_KIND)/values.yaml \
			--values $(STORAGE_KIND)/values.yaml
	$(MAKE) -C $(TLS_KIND) deploy

delete: 
	- $(helm) delete --purge $(COMPONENT_NAME)

clean:
	rm -rf $(HELM_HOME)

output:
	@ echo 
	@ echo Outputs:
	@ echo pull_secret = $(PULL_SECRET)
	@ echo $(shell $(MAKE) -C $(TLS_KIND) output)
	@ echo


-include ../../Mk/phonies
