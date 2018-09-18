.DEFAULT_GOAL := deploy

HELM_HOME      ?= ./.helm
COMPONENT_NAME ?= istio
NAMESPACE      ?= istio-system
DOMAIN_NAME    ?= default
ISTIO_VERSION  ?= 1.0.0

kubectl        ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm           ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init fetch namespace crds install

namespace:
	$(kubectl) apply -f namespace.yaml
.PHONY: namespace

crds:
	$(kubectl) apply -f istio-$(ISTIO_VERSION)/install/kubernetes/helm/istio/templates/crds.yaml
.PHONY: crds

init:
	@mkdir -p $(HELM_HOME)
	$(helm) init --client-only --upgrade --wait
.PHONY: init

# https://github.com/istio/istio/issues/7505
fetch: istio-$(ISTIO_VERSION)

istio-$(ISTIO_VERSION):
	curl -L https://github.com/istio/istio/archive/$(ISTIO_VERSION).tar.gz | \
		tar xz istio-$(ISTIO_VERSION)/install/kubernetes/helm/istio

install:
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install istio-$(ISTIO_VERSION)/install/kubernetes/helm/istio \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--wait \
			--values values.yaml
.PHONY: install

undeploy:
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
.PHONY: undeploy

clean:
	@rm -rf $(HELM_HOME)
.PHONY: clean
