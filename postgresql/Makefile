.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export NAMESPACE    	   	 ?= postgresql
export COMPONENT_NAME      ?= postgresql
export DOMAIN_NAME         ?= default 
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init fetch wait install output
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
		--untar stable/postgresql
.PHONY: fetch

install:
	$(kubectl) apply -f namespace.yaml
ifeq ($(findstring $(COMPONENT_NAME), $(shell $(helm) list -q | xargs)),)
	$(helm) install charts/postgresql \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--values values.yaml
endif
.PHONY: install

undeploy: init
	$(helm) delete $(COMPONENT_NAME)
	# $(helm) undeploy -f hub.component
.PHONY: undeploy

clean:
	@rm -rf $(HELM_HOME)
	@rm -rf charts

output:
	@echo Outputs:
	@echo database_url=$(COMPONENT_NAME)-postgresql.$(NAMESPACE).svc.cluster.local
	@echo PostgreSQL has been installed successfully
.PHONY: output
