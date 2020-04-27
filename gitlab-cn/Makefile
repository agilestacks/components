.DEFAULT_GOAL := deploy

export TF_VAR_component          ?= gitlab-cn
export TF_VAR_domain_name        ?= test.dev.superhub.io
export TF_VAR_namespace          ?= gitlab
export TF_VAR_kubeconfig_context ?= $(TF_VAR_domain_name)

export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(TF_VAR_domain_name)-$(TF_VAR_component)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log
export HELM_HOME   ?= $(shell pwd)/.helm

CHART         ?= gitlab
CHART_VERSION ?= 1.7.5
CLOUD_KIND    ?= aws
HELM_REPO     ?= https://charts.gitlab.io/
TLS_KIND      ?= letsencrypt

HELM_VALUES   ?= --values values.yaml
ifeq ($(TLS_KIND), acm)
HELM_VALUES += --values aws/$(TLS_KIND)/values.yaml)
endif

CHART_DIR := $(HELM_HOME)/charts/$(CHART)

kubectl ?= kubectl --context="$(TF_VAR_domain_name)" --namespace="$(TF_VAR_namespace)"
helm    ?= helm --kube-context="$(TF_VAR_domain_name)" --tiller-namespace="kube-system"
terraform   ?= terraform-v0.11
TF_CLI_ARGS ?= -no-color -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan


ifneq (,$(filter $(CLOUD_KIND),aws hybrid))
STATE_BACKEND_CONFIG := -backend-config="bucket=$(STATE_BUCKET)" \
        		-backend-config="region=$(STATE_REGION)" \
				-backend-config="key=$(TF_VAR_domain_name)/$(TF_VAR_component)/terraform.tfstate" \
				-backend-config="profile=$(AWS_PROFILE)"
else ifeq ($(CLOUD_KIND),gcp)
STATE_BACKEND_CONFIG := -backend-config="bucket=$(STATE_BUCKET)" \
        		-backend-config="region=$(STATE_REGION)" \
				-backend-config="prefix=$(TF_VAR_domain_name)/$(TF_VAR_component)" \
				-backend-config="credentials=$(GOOGLE_APPLICATION_CREDENTIALS)"
else ifeq ($(CLOUD_KIND),azure)
STATE_BACKEND_CONFIG := -backend-config="storage_account_name=$(STATE_BUCKET)" \
				-backend-config="container_name=$(STATE_CONTAINER)" \
				-backend-config="resource_group_name=$(TF_VAR_azure_resource_group_name)" \
				-backend-config="key=$(TF_VAR_domain_name)/$(TF_VAR_component)/terraform.tfstate"
else
$(error cloud.kind / CLOUD_KIND must be one of: aws, azure, gcp, hybrid)
endif


deploy: clean init fetch purge install plan apply configure

$(TF_DATA_DIR):
	@mkdir -p "$@"

$(CHART_DIR):
	@mkdir -p "$(@D)"
	$(helm) init --client-only --upgrade
	$(helm) repo add gitlab $(HELM_REPO)
	$(helm) repo update
	$(helm) fetch gitlab/$(CHART) \
		--destination "$(@D)" \
		--untar \
		--version $(CHART_VERSION)

init: $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
		$(STATE_BACKEND_CONFIG) \
		./$(CLOUD_KIND)

fetch: $(CHART_DIR)

purge:
	$(kubectl) delete secret gitlab-registry-storage
	$(kubectl) delete secret gitlab-rails-storage
	$(kubectl) delete secret gitlab-backup-storage
	$(helm) list --deleted --failed -q --namespace $(TF_VAR_namespace) | grep -E '^$(TF_VAR_component)$$' && \
	  $(helm) delete --purge $(TF_VAR_component) || exit 0

install: $(CHART_DIR)
	-$(kubectl) get namespace $(TF_VAR_namespace) 2>/dev/null || \
		$(kubectl) create namespace $(TF_VAR_namespace)
	-$(kubectl) create -f oidc-crd.yaml
	-$(kubectl) create secret generic gitlab-dex-oicd --from-file=provider=gitlab-dex-provider.yaml
	-scripts/create_minio_secret.sh
	$(MAKE) -C $(CLOUD_KIND) $@
	$(helm) list -q --namespace $(TF_VAR_namespace) | grep -E '^$(TF_VAR_component)$$' || \
	  $(helm) install $^ \
	  --timeout 700 \
	  --name $(TF_VAR_component) \
	  --namespace $(TF_VAR_namespace) \
	  --replace \
	  --wait \
	  $(HELM_VALUES) \
	  --version $(CHART_VERSION)
	  #$(MAKE) -C $(CLOUD_KIND) dns

undeploy: init destroy apply
	$(helm) list -q --namespace $(TF_VAR_namespace) | grep -E '^$(TF_VAR_component)$$' && \
	  $(helm) delete --purge $(TF_VAR_component) || exit 0
	-$(kubectl) delete secret generic gitlab-dex-oicd
	-$(kubectl) delete -f oidc-crd.yaml | true

plan:
	$(terraform) plan $(TF_CLI_ARGS) -refresh=true -module-depth=-1 -out=$(TFPLAN) ./$(CLOUD_KIND)

refresh:
	$(terraform) refresh $(TF_CLI_ARGS) ./$(CLOUD_KIND)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)
	@echo

destroy: TF_CLI_ARGS+=-destroy
destroy: plan

clean:
	rm -rf $(HELM_HOME) $(CHART_DIR) $(TF_DATA_DIR)

wait-dns: WAIT_TIMEOUT:=1200
wait-dns: URL:=$(lastword $(subst ://, ,$(GITLAB_URL)))
wait-dns:
	$(eval timeout := $(shell echo "`date +%s` + $(WAIT_TIMEOUT)" | bc ))
	@ echo Waiting for $(URL) to respond
	@ while [ "`date +%s`" -le "$(timeout)" ]; do \
		result="`nslookup $(URL) > /dev/null; echo $$?`"; \
		test "$$result" -ne "0" || exit 0; \
		echo "Still waiting..."; \
		sleep 2; \
	done; \
	echo "ERROR timeout $(WAIT_TIMEOUT)sec"; \
	exit 1

wait-ready: WAIT_TIMEOUT:=1200
wait-ready: URL:=$(GITLAB_URL)/-/readiness
wait-ready:
	$(eval timeout := $(shell echo "`date +%s` + $(WAIT_TIMEOUT)" | bc ))
	@ echo Waiting for $(URL) to respond ready
	@ while [ "`date +%s`" -le "$(timeout)" ]; do \
		code="`curl -kssLo /dev/null -w "%{http_code}" $(URL)`"; \
		if test "$$code" -eq "200"; then \
			resp=`curl -kssL $(URL)`; \
			test `echo $$resp | jq -r .status` = "ok" \
				&& exit 0 \
				|| echo "Gitlab responded: $$resp"; \
		fi; \
		echo "Still waiting..."; \
		sleep 2; \
	done; \
	echo "ERROR timeout $(WAIT_TIMEOUT)sec"; \
	exit 1

wait: wait-dns wait-ready

configure: wait
	scripts/create_bot_account.sh
	scripts/create_minio_buckets.sh
	@ echo "Generating gitlab token for: $(GITLAB_URL)"
	@ $(kubectl) run --generator=run-pod/v1 --rm -i gitlab-token-generation \
		--image=docker.io/agilestacks/gitlab-token-generator:latest \
		--env "GITLAB_URL=$(GITLAB_URL)" \
		--env "GITLAB_ADMIN_USER=$(GITLAB_SERVICEACCOUNT)" \
		--env "GITLAB_ADMIN_PASSWD=$(GITLAB_SERVICEACCOUNT_PASS)"

-include ../Mk/phonies
.PHONY: wait wait-dns wait-ready
