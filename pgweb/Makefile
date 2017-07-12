.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export NAMESPACE           ?= postgresql
export COMPONENT_NAME      ?= pgweb
export DOMAIN_NAME         ?= default 
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"


deploy: clean init wait install

init:
	@mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade

install:
	@$(helm) install . \
		--name $(COMPONENT_NAME) \
		--namespace $(NAMESPACE) \
		--replace \
		--values values.yaml
.PHONY: install

undeploy: init
	$(helm) delete --purge $(COMPONENT_NAME)
.PHONY: undeploy

clean:
	@yes n | rm -rf $(HELM_HOME)
	@yes n | rm -rf charts

wait:
	@for i in $$(seq 1 60); do \
		if $(helm) version; then \
			exit 0; \
		fi; \
		echo "Waiting for Tiller pod is up and running ($$i)..."; \
		sleep 10; \
	done; \
	echo "Timeout waiting for Tiller" \
	exit 1
