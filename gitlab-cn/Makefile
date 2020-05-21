.DEFAULT_GOAL := deploy

export COMPONENT_NAME ?= gitlab-cn
export DOMAIN_NAME    ?= test.dev.superhub.io
export NAMESPACE      ?= gitlab

export HELM_HOME      ?= $(shell pwd)/.helm

CHART         ?= gitlab
CHART_VERSION ?= 3.3.5
CLOUD_KIND    ?= aws
HELM_REPO     ?= https://charts.gitlab.io/
TLS_KIND      ?= letsencrypt

HELM_VALUES   ?= --values values.yaml
ifeq ($(TLS_KIND), acm)
HELM_VALUES += --values aws/$(TLS_KIND)/values.yaml)
endif

CHART_DIR := $(HELM_HOME)/charts/$(CHART)
GITLAB_CRDS_URL   := https://gitlab.com/gitlab-org/charts/gitlab/raw/v${CHART_VERSION}/support/crd.yaml

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm3 --kube-context="$(DOMAIN_NAME)"

deploy: clean purge install configure

$(CHART_DIR):
	@mkdir -p "$(@D)"
	$(helm) repo add gitlab $(HELM_REPO)
	$(helm) repo update
	$(helm) fetch gitlab/$(CHART) \
		--destination "$(@D)" \
		--untar \
		--version $(CHART_VERSION)

purge:
	-$(kubectl) delete secret gitlab-registry-storage
	-$(kubectl) delete secret gitlab-rails-storage
	-$(kubectl) delete secret gitlab-backup-storage
	-$(kubectl) delete -f $(GITLAB_CRDS_URL)
	$(helm) list --failed --pending -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
	  $(helm) --namespace $(NAMESPACE) delete $(COMPONENT_NAME) || exit 0

install: $(CHART_DIR)
	-$(kubectl) get namespace $(NAMESPACE) 2>/dev/null || $(kubectl) create namespace $(NAMESPACE)
	-$(kubectl) create namespace $(NAMESPACE)
	-$(kubectl) apply -f $(GITLAB_CRDS_URL)
	-$(kubectl) create -f oidc-crd.yaml
	-$(kubectl) create secret generic gitlab-dex-oicd --from-file=provider=gitlab-dex-provider.yaml
	-scripts/create_bucket_secret.sh
	$(helm) upgrade $(COMPONENT_NAME) $^ \
          --install \
          --atomic \
	  --timeout 20m \
	  --namespace $(NAMESPACE) \
	  --wait \
	  $(HELM_VALUES) \
	  --version $(CHART_VERSION)

undeploy:
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
	  $(helm) --namespace $(NAMESPACE) delete $(COMPONENT_NAME) || exit 0
	$(helm) list --pending --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
	  $(helm) --namespace $(NAMESPACE) delete $(COMPONENT_NAME) || exit 0
	-$(kubectl) delete secret generic gitlab-dex-oicd
	-kubectl --context="$(DOMAIN_NAME)" delete ClusterRole $(COMPONENT_NAME)-prometheus-server
	-kubectl --context="$(DOMAIN_NAME)" delete ClusterRoleBinding $(COMPONENT_NAME)-prometheus-server
	-$(kubectl) delete -f oidc-crd.yaml | true

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
	scripts/create_buckets.sh
	@ echo "Generating gitlab token for: $(GITLAB_URL)"
	@ $(kubectl) run --generator=run-pod/v1 --rm -i gitlab-token-generation \
		--image=docker.io/agilestacks/gitlab-token-generator:latest \
		--env "GITLAB_URL=$(GITLAB_URL)" \
		--env "GITLAB_ADMIN_USER=$(GITLAB_SERVICEACCOUNT)" \
		--env "GITLAB_ADMIN_PASSWD=$(GITLAB_SERVICEACCOUNT_PASS)"

-include ../Mk/phonies
.PHONY: wait wait-dns wait-ready
