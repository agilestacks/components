.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export NAMESPACE    	   ?= vault
export COMPONENT_NAME      ?= vault-service
export DOMAIN_NAME         ?= default
export INGRESS_ENABLED	   ?= false
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"


deploy: clean init wait install output
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
	$(kubectl) run --rm -i --tty --env VAULT_ADDR=http://$(COMPONENT_NAME)-vault.$(NAMESPACE).svc.cluster.local:8200 \
	vault-init --image=vault --restart=Never -n default -- /bin/sh -c "vault init"
.PHONY: install

undeploy: init
	$(helm) del --purge $(COMPONENT_NAME)
.PHONY: undeploy

clean:
	@rm -rf $(HELM_HOME)
	@rm -rf charts

output:
	@echo Outputs:
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