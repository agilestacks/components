.DEFAULT_GOAL := deploy

HELM_HOME      ?= ./.helm
COMPONENT_NAME ?= istio
NAMESPACE      ?= istio-system
DOMAIN_NAME    ?= default
ISTIO_VERSION  ?= 1.0.2

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init fetch patch namespace purge install usage

namespace:
	$(kubectl) apply -f namespace.yaml

init:
	@mkdir -p $(HELM_HOME)
	$(helm) init --client-only --upgrade --wait

# https://github.com/istio/istio/issues/7505
fetch: istio-$(ISTIO_VERSION)

istio-$(ISTIO_VERSION):
	curl -L https://github.com/istio/istio/archive/$(ISTIO_VERSION).tar.gz | \
		tar xz istio-$(ISTIO_VERSION)/install/kubernetes/helm/istio

# https://github.com/istio/istio/pull/7625
patch:
	@sed -i~ -e 's/serviceName: .*/serviceName: servicegraph/' \
		istio-$(ISTIO_VERSION)/install/kubernetes/helm/istio/charts/servicegraph/templates/ingress.yaml
	@rm istio-$(ISTIO_VERSION)/install/kubernetes/helm/istio/charts/servicegraph/templates/ingress.yaml~
.PHONY: patch

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) && \
		$(kubectl) get crd -o name | grep -F istio.io | xargs $(kubectl) delete || exit 0

install:
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install istio-$(ISTIO_VERSION)/install/kubernetes/helm/istio \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--wait \
			--values values.yaml.$(ISTIO_VERSION)

usage:
	@echo
	@echo Enable automatic sidecar injection by labeling a namespace:
	@echo kubectl label namespace NAMESPACE istio-injection=enabled
	@echo https://istio.io/docs/setup/kubernetes/sidecar-injection/
	@echo

undeploy:
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
	-$(kubectl) get crd -o name | grep -F istio.io | xargs $(kubectl) delete

clean:
	@rm -rf $(HELM_HOME)

include ../Mk/phonies
