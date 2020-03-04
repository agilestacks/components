.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= cert-manager
DOMAIN_NAME    ?= test.dev.superhub.io
NAMESPACE 	   ?= cert-manager
HELM_CHART     ?= jetstack/cert-manager
CHART_VERSION  ?= v0.12.0
TAG            ?= release-0.12
KUBE_FLAVOR    ?=

export HELM_HOME ?= $(shell pwd)/.helm

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

ADDITIONAL_VALUES :=

deploy: clean init fetch purge crds keys install
ifeq ($(KUBE_FLAVOR),openshift)
deploy: openshift
ADDITIONAL_VALUES := --values values-openshift.yaml
endif
deploy: issuer
ifeq ($(CA_ISSUER_ENABLED),true)
deploy: ca-issuer
endif

ifdef SOLVER_AWS_SECRET_KEY
deploy: keys
endif


init:
	@mkdir -p $(HELM_HOME) charts
	$(helm) init --client-only --upgrade

fetch:
	$(helm) repo add jetstack https://charts.jetstack.io
	$(helm) fetch \
		--destination charts \
		--untar $(HELM_CHART) \
		--version $(CHART_VERSION)

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) && \
		$(kubectl) get crd -o name | grep -F certmanager.k8s.io | xargs $(kubectl) delete || exit 0

crds:
	$(kubectl) apply -f namespace.yaml
	$(kubectl) apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/$(TAG)/deploy/manifests/00-crds.yaml
	@echo "Waiting for CRDs to install"; \
	for i in $$(seq 1 30); do \
		if test $$($(kubectl) get crds | grep -F cert-manager.io | wc -l) -ge 6; then \
			echo "done"; \
			exit 0; \
		fi; \
		echo "still waiting"; \
		sleep 10; \
	done; \
	echo "timeout"; \
	exit 1;
.PHONY: crds

keys:
	$(kubectl) -n $(NAMESPACE) delete secret solver-aws-secret-key || true
	$(kubectl) -n $(NAMESPACE) create secret generic solver-aws-secret-key --from-literal=secret-access-key="$(SOLVER_AWS_SECRET_KEY)" --from-literal=access-key-id=$(SOLVER_AWS_ACCESS_KEY)

install:
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install charts/$(notdir $(HELM_CHART)) \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--wait \
			--values values.yaml \
			$(ADDITIONAL_VALUES) \
			--version $(CHART_VERSION)

# TODO do we still need this?
# https://github.com/jetstack/cert-manager/blob/master/deploy/charts/cert-manager/templates/deployment.yaml
openshift:
	$(kubectl) apply -f cert-manager-openshift-rbac-patch.yaml
.PHONY: openshift

issuer:
	for i in $$(seq 1 24); do \
		if $(kubectl) apply -f prod-cluster-issuer.yaml; then exit 0; fi; \
		sleep 5; \
	done; \
	exit 1
	$(kubectl) apply -f staging-cluster-issuer.yaml
.PHONY: issuer

ca-issuer:
	$(kubectl) apply -f ca-issuer-keys.yaml
	$(kubectl) apply -f ca-cluster-issuer.yaml
.PHONY: ca-issuer

undeploy: init
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
	-$(kubectl) get crd -o name | grep -F certmanager.k8s.io | xargs $(kubectl) delete

clean:
	rm -rf $(HELM_HOME) charts/$(notdir $(HELM_CHART))

-include ../Mk/phonies
