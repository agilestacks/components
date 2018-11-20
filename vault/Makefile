.DEFAULT_GOAL := deploy

COMPONENT_NAME   ?= vault
DOMAIN_NAME      ?= dev.kubernetes.delivery
NAMESPACE    	 ?= vault
INGRESS_ENABLED  ?= false
SECRET_SHARES    ?= 5
SECRET_THRESHOLD ?= 3
VAULT_PORT       ?= 8200
VAULT_LOCAL_PORT ?= 31321

export VAULT_ADDR        ?= http://127.0.0.1:$(VAULT_LOCAL_PORT)
export VAULT_SKIP_VERIFY ?= true

export HELM_HOME ?= $(shell pwd)/.helm

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
vault   ?= vault

UNSEAL_FILE := .vault/unseal.$(DOMAIN_NAME).json

deploy: clean init purge install sleep connect enable unseal force-disconnect output

sleep:
	@echo Waiting 30sec for Vault pod
	@sleep 30

init:
	@mkdir -p .vault $(HELM_HOME)
	@$(helm) init --client-only --upgrade

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

install:
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install . \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--wait \
			--values values.yaml

# If Vault is not initialized then we're in first time deploy - initialize and create fresh unseal file.
#
# Otherwise, it might be a restore from backup - etcd is restored, Vault database is initialized but we
# have no unseal file. Render unseal file from ${component.vault.unseal.file}.
#
# If the file is too small - the size of a valid unseal file is usually 445 bytes, then this is not a
# restore but redeploy. Check there is already valid unseal file. If not, then render it from outputs.
enable:
	@if test "`curl -sS $(VAULT_ADDR)/v1/sys/health | jq -rM .initialized`" != "true"; then \
		echo "Initialize vault"; \
		curl \
	  		-sS \
			-X PUT \
			-d "{\"secret_shares\":$(SECRET_SHARES), \"secret_threshold\":$(SECRET_THRESHOLD)}" \
			$(VAULT_ADDR)/v1/sys/init | jq '{keys, root_token}' > $(UNSEAL_FILE); \
	else \
		$(HUB) render restore/unseal-file.json.template; \
		if test 400 -le $$(wc -c < restore/unseal-file.json); then \
			mv restore/unseal-file.json $(UNSEAL_FILE); \
		else \
			if test 400 -gt $$(wc -c < $(UNSEAL_FILE)); then \
				$(HUB) render restore/unseal-outputs.json.template; \
				if test 400 -le $$(wc -c < restore/unseal-outputs.json); then \
					mv restore/unseal-outputs.json $(UNSEAL_FILE); \
				else \
					echo Vault is initialized but no unseal file is found nor it could be recreated; \
					exit 1; \
				fi; \
			fi; \
		fi; \
	fi;

backup:
	if test ! -f $(UNSEAL_FILE) || jq -e 'has("keys")|not' < $(UNSEAL_FILE); then \
		$(HUB) render restore/unseal-outputs.json.template && \
		mkdir -p .vault && \
		mv restore/unseal-outputs.json $(UNSEAL_FILE); \
	fi;
	@echo Outputs:
	@echo component.vault.unseal.file = $$(base64 < $(UNSEAL_FILE))
	@echo

unseal:
	@for i in $$(seq 1 $(SECRET_THRESHOLD)); do \
		$(vault) operator unseal `cat $(UNSEAL_FILE) | jq -Mr .keys[$$i]`; \
	done;
.PHONY: unseal

seal: login
	$(vault) seal
.PHONY: seal

undeploy: init disconnect
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
	# rm -f $(UNSEAL_FILE)

login:
	$(vault) login $(shell cat $(UNSEAL_FILE) | jq -rM .root_token)

connect: disconnect
	@echo Searching for Vault pod
	$(kubectl) get pods
	$(eval VAULT_POD=$(shell $(kubectl) get pods -l app=vault,release=$(COMPONENT_NAME) --output=jsonpath={.items..metadata.name}))
	@if test -z "$(VAULT_POD)"; then \
		echo Cannot find Vault pod; \
		exit 1; \
	fi
	@echo Vault pod is $(VAULT_POD)

	@echo Start proxy to pod/$(VAULT_POD)
	$(kubectl) port-forward $(VAULT_POD) $(VAULT_LOCAL_PORT):$(VAULT_PORT) >/dev/null 2>&1 &
	@sleep 2
	@echo Connecting to vault at $(VAULT_ADDR)
	@for i in $$(seq 1 60); do \
		if curl -sS $(VAULT_ADDR)/v1/sys/health; then \
			exit 0; \
		fi; \
		echo "Waiting for pod/$(VAULT_POD) to connect ($$i)..."; \
		sleep 3; \
	done; \
	echo "Timeout for pod/$(VAULT_POD)"; \
	exit 1

force-disconnect:
	-@$(MAKE) disconnect
.PHONY: force-disconnect

disconnect:
	@echo Drop connection to Vault pod
	-@ps aux | grep -E "kubectl.*port-forward.*$(VAULT_LOCAL_PORT):$(VAULT_PORT)" | grep -v grep | awk '{print $$2}' | xargs kill

clean:
	rm -rf $(HELM_HOME) charts

output:
	@echo
	@echo Outputs:
	@echo root_token=$(shell cat $(UNSEAL_FILE) | jq -rM .root_token )
	@echo vault_url=http://$(COMPONENT_NAME)-vault.$(NAMESPACE).svc.cluster.local:$(VAULT_PORT)
	@cat $(UNSEAL_FILE) | jq -Mr '.keys | to_entries | map("unseal_key_" + (.key+1|tostring) + "=" + .value) | .[]'
	@echo
	@echo Vault has been installed and initialized successfully.

-include ../Mk/phonies
