.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= istio
NAMESPACE      ?= istio-system
DOMAIN_NAME    ?= default
ISTIO_VERSION  ?= 1.2.2

export HELM_HOME ?= $(shell pwd)/.helm

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init repo namespace purge install usage

namespace:
	$(kubectl) apply -f namespace.yaml

init:
	@mkdir -p $(HELM_HOME)
	$(helm) init --client-only --upgrade --wait

repo:
	$(helm) repo add istio https://storage.googleapis.com/istio-release/releases/$(ISTIO_VERSION)/charts/
.PHONY: repo

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)-init$$' && \
		$(helm) delete --purge $(COMPONENT_NAME)-init && \
		$(kubectl) get crd -o name | grep -F istio.io | xargs $(kubectl) delete || exit 0

install: install-init wait-crds install-app

install-init:
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)-init$$' || \
		$(helm) install istio/istio-init \
			--name $(COMPONENT_NAME)-init \
			--namespace $(NAMESPACE) \
			--version $(ISTIO_VERSION) \
			--replace \
			--wait \
			--values values.yaml.$(ISTIO_VERSION)
.PHONY: install-init

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
.PHONY: wait-crds

install-app:
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install istio/istio \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--version $(ISTIO_VERSION) \
			--replace \
			--wait \
			--values values.yaml.$(ISTIO_VERSION)
.PHONY: install-app

usage:
	@echo https://istio.io/docs/setup/kubernetes/sidecar-injection/

undeploy:
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)-init$$' && \
		$(helm) delete --purge $(COMPONENT_NAME)-init || exit 0
	-$(kubectl) get crd -o name | grep -F istio.io | xargs $(kubectl) delete

clean:
	@rm -rf $(HELM_HOME)

-include ../Mk/phonies
