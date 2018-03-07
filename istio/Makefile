.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export COMPONENT_NAME      ?= istio
export NAMESPACE           ?= ingress
export DOMAIN_NAME         ?= default
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init fetch install
    $(kubectl) apply -f namespace.yaml
.PHONY: deploy

init:
    mkdir -p $(HELM_HOME)
    @$(helm) init --client-only --upgrade --wait
    -$(helm) repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com
    @mkdir -p tmp

fetch:
    $(helm) fetch \
            --destination charts \
            --untar incubator/istio
.PHONY: fetch

install:
    $(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' || \
        $(helm) install incubator/istio \
            --name $(COMPONENT_NAME) \
            --namespace $(NAMESPACE) \
            --replace \
            --wait \
            --values values.yaml
endif
.PHONY: install

undeploy: init
    $(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' && \
        $(helm) delete --purge $(COMPONENT_NAME) || exit 0
.PHONY: undeploy

clean:
    rm -rf $(HELM_HOME)
    rm -rf tmp

