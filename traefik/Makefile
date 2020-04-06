.DEFAULT_GOAL := deploy

export TF_VAR_component          ?= traefik
export TF_VAR_domain_name        ?= test.dev.superhub.io
export TF_VAR_namespace          ?= ingress
export TF_VAR_kubeconfig_context ?= $(TF_VAR_domain_name)

export TF_VAR_azure_resource_group_name ?= superhub-eastus2

CLOUD_KIND          ?= aws
ACM_CERTIFICATE_ARN ?=
CHART_VERSION       ?= 1.68.5
CHART               ?= stable/traefik
HELM_TIMEOUT        ?= 900
HUB_PROVIDES        ?=

STATE_BUCKET    ?= terraform.agilestacks.com
STATE_REGION    ?= us-east-1
STATE_CONTAINER ?= agilestacks

export AWS_DEFAULT_REGION ?= us-east-2
export HELM_HOME          ?= $(shell pwd)/.helm

export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(TF_VAR_domain_name)-$(TF_VAR_component)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log

helm        ?= helm --kube-context="$(TF_VAR_kubeconfig_context)" --tiller-namespace="kube-system"
terraform   ?= terraform-v0.11
TF_CLI_ARGS ?= -no-color -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan

VALUES_FILE:=values.yaml
ifneq (,$(ACM_CERTIFICATE_ARN))
	PROTOCOL:=https
	ACM_VALUES_FILE:=--values aws/values-acm.yaml
else
ifneq (,$(filter cert-manager,$(HUB_PROVIDES)))
	PROTOCOL:=https
	TLS_VALUES_FILE:=--values values-tls.yaml --values $(CLOUD_KIND)/values-tls.yaml
	DASHBOARD_VALUES_FILE:=--values values-dashboard.yaml
	PROVIDES:=tls-ingress
else
	PROTOCOL:=http
endif
endif

deploy: clean init fetch patch purge install plan output apply wait

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

$(TF_DATA_DIR):
	@mkdir -p $@

init: $(TF_DATA_DIR)
	@mkdir -p $(HELM_HOME) charts
	$(helm) init --client-only --upgrade --wait
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
		$(STATE_BACKEND_CONFIG) \
		./$(CLOUD_KIND)

fetch:
	$(helm) fetch \
		--destination charts \
		--untar $(CHART) \
		--version $(CHART_VERSION)

# https://github.com/helm/charts/commit/0488c623ee045c90ac3d34a6e7803b3da83a2f62#diff-7085afc89c71e92e4515de4fe9ca0260
# https://github.com/agilestacks/auth-operator/commit/a47a74dd75bf8133cf514f430581db2ca3a1fe00#diff-310eef67e361cf942a183144b1451b0bR166
patch:
	-@sed -i~ -e 's/servicePort: dashboard-http/servicePort: 80/' \
			charts/traefik/templates/dashboard-ingress.yaml && \
		rm -f charts/traefik/templates/dashboard-ingress.yaml~

purge:
	$(helm) list --deleted --failed -q --namespace $(TF_VAR_namespace) | grep -E '^$(TF_VAR_component)$$' && \
		$(helm) delete --purge $(TF_VAR_component) || exit 0

install:
	if ! $(helm) list -q --namespace $(TF_VAR_namespace) | grep -E '^$(TF_VAR_component)$$'; then \
		$(helm) install charts/$(notdir $(CHART)) \
			--name $(TF_VAR_component) \
			--namespace $(TF_VAR_namespace) \
			--wait \
			--timeout $(HELM_TIMEOUT) \
			--values $(VALUES_FILE) \
			$(ACM_VALUES_FILE) \
			$(TLS_VALUES_FILE) \
			$(DASHBOARD_VALUES_FILE) \
			--version $(CHART_VERSION); \
	else \
		$(MAKE) upgrade; \
	fi

upgrade:
	$(helm) upgrade $(TF_VAR_component) charts/$(notdir $(CHART)) \
		--namespace $(TF_VAR_namespace) \
		--wait \
		--values $(VALUES_FILE) \
		$(ACM_VALUES_FILE) \
		$(TLS_VALUES_FILE) \
		$(DASHBOARD_VALUES_FILE) \
		--version $(CHART_VERSION)

plan:
	$(terraform) plan $(TF_CLI_ARGS) -refresh=true -module-depth=-1 -out=$(TFPLAN) ./$(CLOUD_KIND)

refresh:
	$(terraform) refresh $(TF_CLI_ARGS) ./$(CLOUD_KIND)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)
	@echo

output:
	@echo
	@echo Outputs:
	@echo ingress_protocol = $(PROTOCOL)
	@echo provides = $(PROVIDES)
	@echo

undeploy: init destroy apply uninstall

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

uninstall:
	$(helm) list -q --namespace $(TF_VAR_namespace) | grep -E '^$(TF_VAR_component)$$' && \
		$(helm) delete --purge $(TF_VAR_component)

clean:
	rm -rf $(HELM_HOME) charts $(TF_DATA_DIR)

wait_app: DOMAIN_NAME:=$(TF_VAR_url_prefix).$(TF_VAR_domain_name)
wait_app: wait_dns

wait_apps: DOMAIN_NAME:=$(TF_VAR_sso_url_prefix).$(TF_VAR_domain_name)
wait_apps: wait_dns

wait_dns: WAIT_TIMEOUT=900
wait_dns:
	$(eval timeout := $(shell echo "`date +%s` + $(WAIT_TIMEOUT)" | bc ))
	@ echo "Waiting $(DOMAIN_NAME) to resolve"
	@ while [ "`date +%s`" -le "$(timeout)" ]; do \
		actual=`nslookup "$(DOMAIN_NAME)" > /dev/null; echo $$?`; \
		if test "$$actual" = "0"; then \
			echo "Done!"; \
			exit 0; \
		fi; \
		echo "Still waiting..	."; \
		sleep 2; \
	done; \
	echo "ERROR timeout $(WAIT_TIMEOUT)sec"; \
	exit 1

wait: wait_apps wait_app

.PHONY: wait_dns wait_app wait_apps sleep

-include ../Mk/phonies
