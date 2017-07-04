.DEFAULT_GOAL := deploy

export SPINNAKER_NAMESPACE ?= spinnaker
export DOMAIN_NAME         ?= default 
export kubectl     				 ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(SPINNAKER_NAMESPACE)"
export helm        				 ?= helm --kube-context="$(DOMAIN_NAME)"

deploy: clean init fetch install
	$(kubectl) apply --namespace $(SPINNAKER_NAMESPACE) -f ingress.yaml
.PHONY: deploy

init:
	@$(helm) init --client-only
	@mkdir -p tmp

fetch:
	$(helm) fetch \
			--destination tmp \
			--untar stable/spinnaker
.PHONY: fetch

install:
	$(helm) install tmp/spinnaker \
			--name $(SPINNAKER_NAMESPACE) \
			--namespace $(SPINNAKER_NAMESPACE) \
			--replace \
			--values values.yaml
.PHONY: install

undeploy: init
	$(helm) delete $(SPINNAKER_NAMESPACE)
	$(helm) undeploy -f hub.component
.PHONY: undeploy

clean:
	rm -rf tmp