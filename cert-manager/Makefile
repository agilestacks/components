.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= cert-manager
DOMAIN_NAME    ?= test.dev.superhub.io
NAMESPACE      ?= cert-manager
HELM_CHART     ?= jetstack/cert-manager
VERSION        ?= v1.1.0

CRD_FILE := charts/$(notdir $(HELM_CHART))/crds.yaml

export HELM_HOME

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy: clean init fetch purge crds install issuer
ifeq ($(CA_ISSUER_ENABLED),true)
deploy: ca-issuer
endif
ifeq ($(AWS_DNS_CREDENTIALS_ENABLED),true)
deploy: aws-dns-key
endif

init:
	@mkdir -p charts

fetch:
	$(helm) repo add jetstack https://charts.jetstack.io
	$(helm) fetch \
		--destination charts \
		--untar $(HELM_CHART) \
		--version $(VERSION)

purge:
	-$(helm) list --uninstalled --failed -q| grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) uninstall $(COMPONENT_NAME)

$(CRD_FILE):
	mkdir -p "$(dir $@)"
	curl -sL -o "$@" https://github.com/jetstack/cert-manager/releases/download/$(VERSION)/cert-manager.crds.yaml
.INTERMEDIATE: $(CRD_FILE)

crds: $(CRD_FILE)
	$(kubectl) apply -f "$^"
	@echo "Waiting for CRDs to install"; \
	for i in $$(seq 1 30); do \
		if $(kubectl) get -f "$^" > /dev/null 2>&1; then \
			echo "Done"; \
			exit 0; \
		fi; \
		echo "Still waiting..."; \
		sleep 10; \
	done; \
	echo "timeout"; \
	exit 1;
.PHONY: crds

install:
	$(kubectl) apply -f namespace.yaml
	$(helm) upgrade $(COMPONENT_NAME) charts/$(notdir $(HELM_CHART)) \
		--install \
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
	$(kubectl) apply -f issuers/prod-cluster-dns-issuer.yaml
	$(kubectl) apply -f issuers/staging-cluster-dns-issuer.yaml
.PHONY: issuer

ca-issuer:
	$(kubectl) apply -f issuers/ca-issuer-keys.yaml
	$(kubectl) apply -f issuers/ca-cluster-issuer.yaml
.PHONY: ca-issuer

aws-dns-key:
	$(kubectl) apply -f issuers/solver-aws-secret-key.yaml
.PHONY: aws-dns-key

undeploy: init
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) uninstall $(COMPONENT_NAME) || exit 0

clean:
	rm -rf $(HELM_HOME) charts/$(notdir $(HELM_CHART))

-include ../Mk/phonies
