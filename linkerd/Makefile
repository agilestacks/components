.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export COMPONENT_NAME      ?= linkerd
export NAMESPACE           ?= ingress
export DOMAIN_NAME         ?= default
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init fetch purge install
    $(kubectl) apply --namespace $(NAMESPACE) -f ingress.yaml
.PHONY: deploy

init:
    mkdir -p $(HELM_HOME)
    @$(helm) init --client-only --upgrade
    @mkdir -p tmp

fetch:
    $(helm) fetch \
            --destination charts \
            --untar stable/linkerd
.PHONY: fetch

purge:
    $(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
        $(helm) delete --purge $(COMPONENT_NAME) || exit 0
.PHONY: purge

install:
    $(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
        $(helm) install charts/linkerd \
            --name $(COMPONENT_NAME) \
            --namespace $(NAMESPACE) \
            --replace \
            --wait \
            --values values.yaml
endif
.PHONY: install

undeploy: init
    $(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
        $(helm) delete --purge $(COMPONENT_NAME) || exit 0
.PHONY: undeploy

clean:
    rm -rf $(HELM_HOME)
    rm -rf tmp
