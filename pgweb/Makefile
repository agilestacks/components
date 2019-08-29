.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= pgweb
RELEASE_NAME   := $(shell echo $(COMPONENT_NAME) | cut -c1-53)
DOMAIN_NAME    ?= test.dev.superhub.io
NAMESPACE      ?= postgresql

export HELM_HOME ?= $(shell pwd)/.helm

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init purge install

init:
	@mkdir -p $(HELM_HOME)
	$(helm) init --client-only --upgrade

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(RELEASE_NAME)$$' && \
		$(helm) delete --purge $(RELEASE_NAME) || exit 0

install:
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(RELEASE_NAME)$$' || \
		$(helm) install . \
			--name $(RELEASE_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--values values.yaml

undeploy: init
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(RELEASE_NAME)$$' && \
		$(helm) delete --purge $(RELEASE_NAME) || exit 0

clean:
	rm -rf $(HELM_HOME)

-include ../Mk/phonies
