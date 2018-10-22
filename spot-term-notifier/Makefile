.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export NAMESPACE    	   ?= spot-term-notifier
export COMPONENT_NAME      ?= spot-term-notifier
export TF_VAR_name         ?= test
export TF_VAR_base_domain  ?= kubernetes.delivery
export DOMAIN_NAME         ?= $(TF_VAR_name).$(TF_VAR_base_domain)
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init purge install output
.PHONY: deploy

init:
	@mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
.PHONY: purge

install:
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install . \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--wait \
			--values values.yaml

undeploy: init
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
.PHONY: undeploy

clean:
	@rm -rf $(HELM_HOME) | true
	@rm -rf charts       | true

output:
	@echo Outputs:
	@echo Spot instance termination notifier has been installed successfully.
.PHONY: output
