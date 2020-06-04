.DEFAULT_GOAL := deploy


COMPONENT_NAME          ?= kubecost
DOMAIN_NAME             ?= test.dev.superhub.io
NAMESPACE               ?= kubecost
HELM_REPO_URL           ?= https://kubecost.github.io/cost-analyzer/
HELM_REPO_NAME          ?= kubecost
HELM_CHART              ?= $(HELM_REPO_NAME)/cost-analyzer
VERSION                 ?= v1.59.0
AWS_DEFAULT_REGION      ?= us-east-2
HELM_HOME               ?= $(shell pwd)/.helm
TF_DATA_DIR             ?= .terraform/$(COMPONENT_NAME)
TF_LOG_PATH             ?= $(TF_DATA_DIR)/terraform.log
TF_CLI_ARGS             ?= -no-color -input=false
TFPLAN                  := $(TF_DATA_DIR)/terraform.tfplan
TFSTATE                 := $(TF_DATA_DIR)/terraform.tfstate
SPOT_DATA_ENABLED       ?= true

terraform      ?= terraform-v0.12
kubectl        ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm           ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

HELM_ARGS_PROJECT_ID    := --set-string kubecostProductConfigs.projectID="`$(terraform) output account_id`"
HELM_ARGS_SPOT_DATA     := --values spot-data-feed.yaml

ifneq ($(SPOT_DATA_ENABLED),true)
    SPOT_DATA_ENABLED:=
    HELM_ARGS_PROJECT_ID:=
    HELM_ARGS_SPOT_DATA:=
endif

deploy: init import plan apply fetch purge install

spot-data:
	rm -rf spot-data-feed.tf
	test -z "$(SPOT_DATA_ENABLED)" || cp spot-data-feed.tf.ignore spot-data-feed.tf

init: $(TF_DATA_DIR) $(HELM_HOME) charts spot-data
	$(helm) init --client-only --upgrade

	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(DOMAIN_NAME)/kubecost/$(COMPONENT_NAME)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"

$(TF_DATA_DIR) $(HELM_HOME) charts:
	@rm -rf $@ && mkdir -p $@


import:
	-$(terraform) import $(TF_CLI_ARGS) aws_spot_datafeed_subscription.kubecost spot-datafeed-subscription


plan:
	$(terraform) plan $(TF_CLI_ARGS) -refresh=true -state="$(TFSTATE)" -out="$(TFPLAN)"

refresh:
	$(terraform) refresh $(TF_CLI_ARGS)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve -state-out="$(TFSTATE)" "$(TFPLAN)"


fetch:
	$(helm) repo add kubecost $(HELM_REPO_URL)
	$(helm) fetch \
		--destination charts \
		--untar $(HELM_CHART) \
		--version $(VERSION)

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' \
		&& $(helm) delete --purge $(COMPONENT_NAME) \
		|| exit 0

install:
	$(kubectl) apply -f namespace.yaml

	if ! $(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$'; then \
		$(helm) install charts/$(notdir $(HELM_CHART)) \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--wait \
			--values values.yaml \
			$(HELM_ARGS_SPOT_DATA) \
			$(HELM_ARGS_PROJECT_ID) \
			--version $(VERSION); \
	else \
		$(MAKE) upgrade; \
	fi

	$(kubectl) apply -f ingress.yaml

upgrade:
	$(helm) upgrade $(COMPONENT_NAME) charts/$(notdir $(HELM_CHART)) \
		--namespace $(NAMESPACE) \
		--wait \
		--values values.yaml \
		$(HELM_ARGS_SPOT_DATA) \
		$(HELM_ARGS_PROJECT_ID) \
		--version $(VERSION)


undeploy: init destroy apply

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan
	$(kubectl) delete -f ingress.yaml
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

-include ../Mk/phonies
