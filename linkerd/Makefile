.DEFAULT_GOAL := deploy

export HELM_HOME ?= $(shell pwd)/.helm

COMPONENT_NAME ?= linkerd
DOMAIN_NAME    ?= dev.kubernetes.delivery
NAMESPACE      ?= ingress

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init fetch purge install
    $(kubectl) apply --namespace $(NAMESPACE) -f ingress.yaml

init:
    @mkdir -p $(HELM_HOME) tmp
    $(helm) init --client-only --upgrade

fetch:
    $(helm) fetch \
            --destination charts \
            --untar stable/linkerd

purge:
    $(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
        $(helm) delete --purge $(COMPONENT_NAME) || exit 0

install:
    $(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
        $(helm) install charts/linkerd \
            --name $(COMPONENT_NAME) \
            --namespace $(NAMESPACE) \
            --replace \
            --wait \
            --values values.yaml

undeploy: init
    $(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
        $(helm) delete --purge $(COMPONENT_NAME) || exit 0

clean:
    rm -rf $(HELM_HOME) tmp

-include ../Mk/phonies
