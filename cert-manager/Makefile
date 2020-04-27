.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= cert-manager
DOMAIN_NAME    ?= test.dev.superhub.io
NAMESPACE 	   ?= cert-manager
HELM_CHART     ?= jetstack/cert-manager
VERSION        ?= v0.14.2

export HELM_HOME ?= $(shell pwd)/.helm

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init fetch purge crds install issuer
ifeq ($(CA_ISSUER_ENABLED),true)
deploy: ca-issuer
endif
ifeq ($(AWS_DNS_CREDENTIALS_ENABLED),true)
deploy: aws-dns-key
endif

init:
	@mkdir -p $(HELM_HOME) charts
	$(helm) init --client-only --upgrade

fetch:
	$(helm) repo add jetstack https://charts.jetstack.io
	$(helm) fetch \
		--destination charts \
		--untar $(HELM_CHART) \
		--version $(VERSION)

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) && \
		$(kubectl) get crd -o name | grep -F certmanager.k8s.io | xargs $(kubectl) delete || exit 0

crds:
	$(kubectl) apply -f https://github.com/jetstack/cert-manager/releases/download/$(VERSION)/cert-manager.crds.yaml
	@echo "Waiting for CRDs to install"; \
	for i in $$(seq 1 30); do \
		if test $$($(kubectl) get crds | grep -F .cert-manager.io | wc -l) -ge 6; then \
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
	if ! $(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$'; then \
		$(helm) install charts/$(notdir $(HELM_CHART)) \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--wait \
			--values values.yaml \
			--version $(VERSION); \
	else \
		$(MAKE) upgrade; \
	fi

upgrade:
	$(helm) upgrade $(COMPONENT_NAME) charts/$(notdir $(HELM_CHART)) \
		--namespace $(NAMESPACE) \
		--wait \
		--values values.yaml \
		--version $(VERSION)

issuer:
	for i in $$(seq 1 12); do \
		if $(kubectl) apply -f issuers/prod-cluster-default-issuer.yaml; then exit 0; fi; \
		sleep 10; \
	done; \
	exit 1
	$(kubectl) apply -f issuers/staging-cluster-default-issuer.yaml
.PHONY: issuer

ca-issuer:
	$(kubectl) apply -f issuers/ca-issuer-keys.yaml
	$(kubectl) apply -f issuers/ca-cluster-issuer.yaml
.PHONY: ca-issuer

aws-dns-key:
	$(kubectl) apply -f issuers/solver-aws-secret-key.yaml
	$(kubectl) apply -f issuers/prod-cluster-dns-issuer.yaml
	$(kubectl) apply -f issuers/staging-cluster-dns-issuer.yaml
.PHONY: aws-dns-key

undeploy: init
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
	-$(kubectl) get crd -o name | grep -F .cert-manager.io | xargs $(kubectl) delete

clean:
	rm -rf $(HELM_HOME) charts/$(notdir $(HELM_CHART))

-include ../Mk/phonies
