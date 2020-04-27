.DEFAULT_GOAL := deploy

COMPONENT_NAME   ?= vault
DOMAIN_NAME      ?= test.dev.superhub.io
NAMESPACE    	 ?= vault
INGRESS_ENABLED  ?= false
SECRET_SHARES    ?= 5
SECRET_THRESHOLD ?= 3
VAULT_PORT       ?= 8200
VAULT_LOCAL_PORT ?= 31321

export VAULT_ADDR        ?= http://127.0.0.1:$(VAULT_LOCAL_PORT)
export VAULT_SKIP_VERIFY ?= true

export HELM_HOME ?= $(shell pwd)/.helm

kubectl := kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    := helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
vault   := vault

UNSEAL_FILE := .vault/unseal.$(DOMAIN_NAME).json
TIMEOUT := 300

ifneq ($(ETCD_ENDPOINT),)
storage := etcd
else ifneq ($(DYNAMODB_TABLE),)
storage := dynamodb
else ifneq ($(BUCKET_NAME),)
storage := $(BUCKET_KIND)
else
$(error One of component.etcd.endpoint, component.dynamodb.table, component.bucket.kind/.name must be provided for Vault storage)
endif

deploy: clean init purge install wait connect enable unseal mount force-disconnect output

init:
	@mkdir -p .vault $(HELM_HOME)
	$(helm) init --client-only --upgrade

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

install:
	-$(kubectl) create ns $(NAMESPACE)
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install . \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--wait \
			--values values.yaml \
			--values values-$(storage).yaml

# If Vault is not initialized then we're in first time deploy - initialize and create fresh unseal file.
#
# Otherwise, it might be a restore from backup - etcd or s3 bucket is restored, Vault database is initialized
# but we have no unseal file. Render unseal file from ${component.vault.unseal.file}.
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

$(UNSEAL_FILE):
	if test ! -f $(UNSEAL_FILE) || jq -e 'has("keys")|not' < $(UNSEAL_FILE); then \
		$(HUB) render restore/unseal-outputs.json.template && \
		mkdir -p .vault && \
		mv restore/unseal-outputs.json $(UNSEAL_FILE); \
	fi;
.PHONY: $(UNSEAL_FILE)

mount: login
	@if ! $(vault) secrets list | grep ^secret/; then \
		echo "Enable KV v1 secrets"; \
		$(vault) secrets enable -version=1 -path=secret -description='Secrets v1' kv; \
	fi
.PHONY: mount

backup: $(UNSEAL_FILE)
	@echo Outputs:
	@echo component.vault.unseal.file = $$(base64 < $(UNSEAL_FILE))
	@echo

unseal: $(UNSEAL_FILE)
	set -e; for i in $$(seq 1 $(SECRET_THRESHOLD)); do \
		$(vault) operator unseal $$(jq -r .keys[$$i] < $(UNSEAL_FILE)); \
	done;
.PHONY: unseal

seal:
	$(vault) operator seal
.PHONY: seal

login: $(UNSEAL_FILE)
	$(vault) login $(shell cat $(UNSEAL_FILE) | jq -rM .root_token)

connect: disconnect
	@echo Searching for Vault pod
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

undeploy: init disconnect
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

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

REPLICAS ?= 1
vault_ready_container:=$(kubectl) get pods -l app=$(COMPONENT_NAME) -o jsonpath='{.items..containerStatuses[?(@.ready==true)].containerID}'
wait:
	$(eval timeout=$(shell echo "`date +%s` + $(TIMEOUT)" | bc ))
	@echo "Waiting for Vault pod to become ready"
	@while test `date +%s` -le "$(timeout)"; do \
		ready_containers=`$(vault_ready_container) | wc -w | xargs`; \
		if test "$$ready_containers" -ge "$(REPLICAS)"; then \
			echo done; \
			exit 0; \
		fi; \
		echo "still waiting (ready: $$ready_containers of $(REPLICAS))..."; \
		sleep 8; \
	done; \
	echo "ERROR timeout $(TIMEOUT)sec"; \
	exit 1

-include ../Mk/phonies
