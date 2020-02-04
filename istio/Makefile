.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= istio
NAMESPACE      ?= istio-system
DOMAIN_NAME    ?= default
ISTIO_VERSION  ?= 1.2.2

export HELM_HOME ?= $(shell pwd)/.helm

CHARTS_DIR := $(abspath $(HELM_HOME))/charts

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

HELM_VALUES_ARGS += -f $(abspath values.yaml)
HELM_VALUES_ARGS += -f $(abspath values-$(ISTIO_VERSION).yaml)

deploy: clean install usage

$(CHARTS_DIR)/%: init repo
	$(helm) fetch istio/$* \
		--version "$(ISTIO_VERSION)" \
		--untar \
		--untardir $(dir $@)

# More info auto-injection: https://github.com/istio/istio/issues/6476#issuecomment-399219937
apply-template-% delete-template-%: $(CHARTS_DIR)/istio
	- $(helm) template $< \
		--namespace "$(NAMESPACE)" \
		-x "$(shell find $< -name '$*')" \
		$(HELM_VALUES_ARGS) \
	| $(kubectl) $(firstword $(subst -, ,$@)) -f -

install: namespace install-istio-init wait-crds install-istio apply-template-mutatingwebhook.yaml

install-istio-init: $(CHARTS_DIR)/istio-init
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)-init$$' || \
		$(helm) install $< \
			--name "$(COMPONENT_NAME)-init" \
			--namespace $(NAMESPACE) \
			--replace --wait $(HELM_VALUES_ARGS)

install-istio: $(CHARTS_DIR)/istio
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install $< \
			 --debug --dep-up \
			--name "$(COMPONENT_NAME)" \
			--namespace "$(NAMESPACE)" \
			--replace --wait $(HELM_VALUES_ARGS)

namespace:
	$(kubectl) get namespace $(NAMESPACE) || \
		$(kubectl) create namespace $(NAMESPACE)

init:
	@ test -f "$(HELM_HOME)/repository/repositories.yaml" || \
		$(helm) init --client-only --upgrade --wait

repo:
	$(helm) repo add istio https://storage.googleapis.com/istio-release/releases/$(ISTIO_VERSION)/charts/

purge-%:
	$(helm) list -a -q --namespace $(NAMESPACE) | grep -E '^$*$$' && \
		$(helm) delete --purge "$*" || exit 0

purge: delete-template-mutatingwebhook.yaml purge-$(COMPONENT_NAME) purge-$(COMPONENT_NAME)-init

undeploy: purge clean

wait-crds:
	@echo "Waiting for CRDs to install"; \
	for i in $$(seq 1 60); do \
		if test $$($(kubectl) get crds | grep -F .istio.io | wc -l) -ge 23; then \
			echo "done"; \
			exit 0; \
		fi; \
		echo "still waiting"; \
		sleep 10; \
	done; \
	echo "timeout"; \
	exit 1;

usage:
	@ echo For using istio sidecars refer to: https://istio.io/docs/setup/kubernetes/sidecar-injection/

clean:
	@rm -rf $(HELM_HOME) $(CHARTS_DIR)

# create-gateway:
# 	$(kubectl) apply -f default-gateway.yaml
# 	$(MAKE) -C $(CLOUD_KIND)/gateway-dns deploy
# drop-gateway:
# 	$(MAKE) -C $(CLOUD_KIND)/gateway-dns undeploy
# 	- $(kubectl) delete -f default-gateway.yaml

-include ../Mk/phonies
.PHONY: install install-istio-init wait-crds install-istio repo
