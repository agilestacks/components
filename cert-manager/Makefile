.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= cert-manager
DOMAIN_NAME    ?= test.dev.superhub.io
NAMESPACE 	   ?= cert-manager
HELM_CHART     ?= jetstack/cert-manager
CHART_VERSION  ?= v0.12.0
TAG            ?= release-0.12
KUBE_FLAVOR    ?=
WAIT_TIMEOUT   ?= 180
export HELM_HOME ?= $(shell pwd)/.helm

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

ADDITIONAL_VALUES :=

deploy: clean init fetch purge crds install issuer
ifeq ($(KUBE_FLAVOR),openshift)
deploy: openshift
ADDITIONAL_VALUES := --values values-openshift.yaml
endif
ifeq ($(CA_ISSUER_ENABLED),true)
deploy: ca-issuer
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

install:
	$(kubectl) apply -f namespace.yaml
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

GREP_CMD := $(kubectl) get crds | grep clusterissuers.cert-manager.io
wait-crds:
	$(eval timeout        := $(shell echo "`date +%s` + $(WAIT_TIMEOUT)" | bc ))
	@ echo "Waiting for $(COMPONENT_NAME) to create clusterissuers CRDs"
	$(eval current_time   := date +%s)
	while [ `$(current_time)` -le "$(timeout)" ]; do \
		if $(GREP_CMD); then \
			echo "Ready!"; \
			exit 0; \
		fi;  \
		echo "Still waiting..."; \
		sleep 6; \
	done; \
	echo "ERROR timeout $(WAIT_TIMEOUT) seconds"; \
	exit 1;

issuer: wait-crds
	$(kubectl) apply -f solvers
.PHONY: issuer

ca-issuer:
	$(kubectl) apply -f internal-ca
.PHONY: ca-issuer

undeploy: init
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
	-$(kubectl) get crd -o name | grep -F certmanager.k8s.io | xargs $(kubectl) delete

clean:
	rm -rf $(HELM_HOME) charts/$(notdir $(HELM_CHART))

-include ../Mk/phonies
