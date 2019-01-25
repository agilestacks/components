.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export COMPONENT_NAME      ?= nfs-provisioner
export NAMESPACE           ?= kube-system
export DOMAIN_NAME         ?= kubernetes-admin@kubernetes
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
deploy: clean init fetch install post_install
	$(kubectl) apply -f namespace.yaml
.PHONY: deploy

init:
	mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade --wait

install: init
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' || \
        $(helm) install --name $(COMPONENT_NAME) \
           --namespace $(NAMESPACE) \
           --wait \
           --values=./values.yaml \
	   ./
.PHONY: install

undeploy: init
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' && \
        $(helm) delete --purge $(COMPONENT_NAME) || exit 0
.PHONY: undeploy

clean:
	rm -rf $(HELM_HOME)

