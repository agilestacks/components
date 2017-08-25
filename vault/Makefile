.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export NAMESPACE    	   ?= vault
export COMPONENT_NAME      ?= vault-service
export DOMAIN_NAME         ?= default
export INGRESS_ENABLED	   ?= false
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

UNSEAL_KEYS = $(shell cat .init.txt |grep '^Unseal' | sed -e 's/ /_/g' | sed -e 's/:_/=/g' | for key in $$(cat -); do echo $$key; done)
ROOT_TOKEN = $(shell cat .init.txt | grep '^Initial' | sed -e 's/ /_/g' | sed -e 's/:_/=/g')

# deploy: enable output
deploy: clean init wait install enable output
.PHONY: deploy

init:
	@mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade

install:
ifeq ($(findstring $(COMPONENT_NAME), $(shell $(helm) list -q | xargs)),)
	$(helm) install . \
		--name $(COMPONENT_NAME) \
		--namespace $(NAMESPACE) \
		--replace \
		--wait \
		--values values.yaml
endif
enable:
	$(kubectl) run -i --rm \
		--env VAULT_ADDR=http://$(COMPONENT_NAME)-vault.$(NAMESPACE).svc.cluster.local:8200 \
		vault-init --image=vault --restart=Never -n default -- /bin/sh -c "vault init -check || vault init" > .init.txt
.PHONY: enable

undeploy: init
ifeq ($(findstring $(COMPONENT_NAME), $(shell $(helm) list -q | xargs)),$(COMPONENT_NAME))
	$(helm) delete --purge $(COMPONENT_NAME)
endif
.PHONY: undeploy

clean:
	@rm -rf $(HELM_HOME)
	@rm -rf charts
	@rm -f .init.txt

output:
	@echo Outputs:
	@for key in $(UNSEAL_KEYS); do \
		echo $$key; \
	done
	@echo $(ROOT_TOKEN)
	@echo vault_url=http://$(COMPONENT_NAME)-vault.$(NAMESPACE).svc.cluster.local:8200
	@echo Vault has been installed and initialized successfully.
.PHONY: output

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

