.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export NAMESPACE    	   ?= vault
export COMPONENT_NAME      ?= vault-service
export DOMAIN_NAME         ?= default
export INGRESS_ENABLED	   ?= false
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
export vault               ?= vault

export SECRET_SHARES       ?= 5
export SECRET_THRESHOLD    ?= 3
export VAULT_PORT          ?= 8200
export VAULT_LOCAL_PORT    := 31321
export VAULT_ADDR          := http://127.0.0.1:$(VAULT_LOCAL_PORT)
export VAULT_SKIP_VERIFY   ?= true

UNSEAL_FILE := .vault/unseal.$(DOMAIN_NAME).json

# deploy: enable output
deploy: clean init wait install sleep connect enable unseal disconnect output
.PHONY: deploy

sleep:
	@sleep 20

init:
	@mkdir -p .vault
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
	@if [ `curl -sS $(VAULT_ADDR)/v1/sys/health | jq -rM .initialized` == "false" ]; then \
		echo "Initialize vault"; \
		curl \
	  		-sS \
			-X PUT \
			-d "{\"secret_shares\":$(SECRET_SHARES), \"secret_threshold\":$(SECRET_THRESHOLD)}" \
			$(VAULT_ADDR)/v1/sys/init > $(UNSEAL_FILE); \
	fi;
.PHONY: enable


unseal:
	@for i in $$(seq 1 $(SECRET_THRESHOLD)); do \
		vault unseal `cat $(UNSEAL_FILE) | jq -Mr .keys[$$i]`; \
	done;
.PHONY: unseal


seal: auth
	vault seal
.PHONY: seal


undeploy: init disconnect
ifeq ($(findstring $(COMPONENT_NAME), $(shell $(helm) list -q | xargs)),$(COMPONENT_NAME))
	$(helm) delete --purge $(COMPONENT_NAME)
endif
	# rm -f $(UNSEAL_FILE)
.PHONY: undeploy

auth:
	@vault auth $(shell cat $(UNSEAL_FILE) | jq -rM .root_token )
.PHONY: auth


connect:
	@$(MAKE) disconnect
	$(eval VAULT_POD=$(shell $(kubectl) get pods -l app=vault,release=$(COMPONENT_NAME) --output=jsonpath={.items..metadata.name}))
	@echo Start proxy to pod/$(VAULT_POD)
	nohup $(kubectl) port-forward $(VAULT_POD) $(VAULT_LOCAL_PORT):$(VAULT_PORT) &
	@sleep 2
	@echo Connecting to vault at $(VAULT_ADDR)
	@for i in $$(seq 1 60); do \
		if curl -sS $(VAULT_ADDR)/v1/sys/health ; then \
			exit 0; \
		fi; \
		echo "Waiting for pod/$(VAULT_POD) to connect ($$i)..."; \
		sleep 3; \
	done; \
	echo "Timeout for pod/$(VAULT_POD)"; \
	exit 1
.PHONY: connect


disconnect:
	@echo Drop connection to vault pod
	@kill $(shell ps aux | grep -E "kubectl*|port-forward*|$(VAULT_LOCAL_PORT):$(VAULT_PORT)" | grep -v grep | awk '{print $$2}' | xargs) | true
.PHONY: disconnect


clean:
	@rm -rf $(HELM_HOME) | true
	@rm -rf charts       | true

output:
	@echo Outputs:
	@echo root_token=$(shell cat $(UNSEAL_FILE) | jq -rM .root_token )
	@echo vault_url=http://$(COMPONENT_NAME)-vault.$(NAMESPACE).svc.cluster.local:$(VAULT_PORT)
	@cat $(UNSEAL_FILE) | jq -Mr '.keys | to_entries | map("unseal_key_" + (.key+1|tostring) + "=" + .value) | .[]'
	@echo component_dir=$(shell pwd)
	@echo
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
	echo "Timeout waiting for Tiller"; \
	exit 1
