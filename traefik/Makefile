.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export NAMESPACE    	   ?= ingress
export COMPONENT_NAME      ?= traefik
export DOMAIN_NAME         ?= default
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
export kind                ?= aws

deploy: clean init fetch wait install output
	bash -e ./deploy-$(kind).sh
	# $(kubectl) apply --namespace $(NAMESPACE) -f ingress.yaml
.PHONY: deploy

init:
	@mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade
	@mkdir -p charts

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


fetch:
	$(helm) fetch \
		--destination charts \
		--untar stable/traefik
.PHONY: fetch

install:
ifeq ($(findstring $(COMPONENT_NAME), $(shell $(helm) list -q | xargs)),)
	$(helm) install charts/traefik \
		--name $(COMPONENT_NAME) \
		--namespace $(NAMESPACE) \
		--replace \
		--wait \
		--values values.yaml
endif
.PHONY: install

undeploy: init
	bash -e ./undeploy-$(kind).sh
ifeq ($(findstring $(COMPONENT_NAME), $(shell $(helm) list -q | xargs)),$(COMPONENT_NAME))
	$(helm) delete $(COMPONENT_NAME)
endif
.PHONY: undeploy

clean:
	@rm -rf $(HELM_HOME)
	@rm -rf charts

output:
	@echo Outputs:
	@echo ingress_fqdn=$(URL_PREFIX).$(DOMAIN_NAME)
	@echo
.PHONY: output
