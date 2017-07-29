.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export NAMESPACE    	   ?= vault
export COMPONENT_NAME      ?= vault-service
export DOMAIN_NAME         ?= default
export INGRESS_ENABLED	   ?= false
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

UNSEAL_KEYS = $(shell $(kubectl) logs po/vault-init -n default |grep '^Unseal' | sed -e 's/ /_/g' | sed -e 's/:_/=/g' | for key in $$(cat -); do echo $$key; done)
ROOT_TOKEN = $(shell $(kubectl) logs po/vault-init -n default | grep '^Initial' | sed -e 's/ /_/g' | sed -e 's/:_/=/g')

deploy: clean init wait install enable output
.PHONY: deploy

init:
	@mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade

install:
	$(helm) install . \
		--name $(COMPONENT_NAME) \
		--namespace $(NAMESPACE) \
		--replace \
		--values values.yaml
enable: wait_pod	
	$(kubectl) run -i \
		--env VAULT_ADDR=http://$(COMPONENT_NAME)-vault.$(NAMESPACE).svc.cluster.local:8200 \
		vault-init --image=vault --restart=Never -n default -- /bin/sh -c "vault init"
.PHONY: enable

undeploy: init
	$(helm) delete --purge $(COMPONENT_NAME)
.PHONY: undeploy

clean:
	@rm -rf $(HELM_HOME)
	@rm -rf charts

output:
	@echo Outputs:
	@for key in $(UNSEAL_KEYS); do \
		echo $$key; \
	done 
	@echo $(ROOT_TOKEN)
	@echo vault_url=http://$(COMPONENT_NAME)-vault.$(NAMESPACE).svc.cluster.local:8200
	@echo Vault has been installed and initialized successfully.
	@$(kubectl) delete po/vault-init -n default
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

wait_pod:
	@for i in $$(seq 1 60); do \
		if $(kubectl) get pods -n ${NAMESPACE} -o jsonpath="{.items[0].status.containerStatuses[0].ready}"|grep true; then \
			exit 0; \
		fi; \
		echo "Waiting for vault pod to be deployed ($$i)..."; \
		sleep 10; \
	done; \
	echo "Timeout waiting for vault pod to be deployed" \
	exit 1