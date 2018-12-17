.DEFAULT_GOAL := deploy

STATE_BUCKET ?= terraform.agilestacks.com
STATE_REGION ?= us-east-1

export TF_VAR_domain             ?= dev.kubernetes.delivery
export TF_VAR_component          ?= harbor
export TF_VAR_namespace          ?= harbor
export TF_VAR_service_prefix     ?= svc
export TF_VAR_nginx_service_name ?= $(TF_VAR_component)-nginx-nginx-ingress-controller
export TF_VAR_pull_secret ?= $(TF_VAR_component)-pull-secret

export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(TF_VAR_domain)-$(TF_VAR_component)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log

export HELM_HOME ?= $(shell pwd)/.helm

NGINX_CHART          ?= stable/nginx-ingress
NGINX_CHART_VERSION  ?= 0.26.0
HARBOR_CHART_VERSION ?= 0.3.0

terraform   ?= terraform-v0.11
TF_CLI_ARGS ?= -no-color -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan

helm    ?= helm --kube-context="$(TF_VAR_domain)" --tiller-namespace="kube-system"
kubectl ?= kubectl --context="$(TF_VAR_domain)" --namespace="$(TF_VAR_namespace)"
git     ?= git

deploy: init purge harbor nginx zone

zone: init-tf plan apply

namespace:
	- $(kubectl) create namespace $(TF_VAR_namespace)

init: namespace
	@rm -rf harbor-helm
	@mkdir -p charts

purge:
	$(helm) list --deleted --failed -q --namespace $(TF_VAR_namespace) | grep -E '^$(TF_VAR_component)$$' && \
		$(helm) delete --purge $(TF_VAR_component) || exit 0
	$(helm) list --deleted --failed -q --namespace $(TF_VAR_namespace) | grep -E '^$(TF_VAR_component)-nginx$$' && \
		$(helm) delete --purge $(TF_VAR_component)-nginx || exit 0

harbor:
	$(helm) init --client-only --upgrade --wait
	$(git) clone --single-branch -b $(HARBOR_CHART_VERSION) https://github.com/goharbor/harbor-helm
	$(helm) dependency update harbor-helm
	$(helm) list -q --namespace $(TF_VAR_namespace) | grep -E '^$(TF_VAR_component)$$' || \
		$(helm)	install harbor-helm \
		    --name $(TF_VAR_component) \
			--namespace $(TF_VAR_namespace) \
			--wait \
			--version $(HARBOR_CHART_VERSION) \
			--values values-harbor.yaml
.PHONY: harbor

nginx:
	$(helm) fetch \
		--destination charts \
		--untar $(NGINX_CHART)
	$(helm) list -q --namespace $(TF_VAR_namespace) | grep -E '^$(TF_VAR_component)-nginx$$' || \
		$(helm) install charts/$(notdir $(NGINX_CHART)) \
			--name $(TF_VAR_component)-nginx \
			--namespace $(TF_VAR_namespace) \
			--wait \
			--version $(NGINX_CHART_VERSION) \
			--values values-nginx.yaml
.PHONY: nginx

$(TF_DATA_DIR):
	@rm -rf $@ && mkdir -p $@

init-tf: $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(TF_VAR_domain)/harbor/$(TF_VAR_component)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"

plan:
	$(terraform) plan $(TF_CLI_ARGS) -refresh=true -module-depth=-1 -out=$(TFPLAN)

refresh:
	$(terraform) refresh $(TF_CLI_ARGS)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)

undeploy: init-tf destroy apply delete

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

delete:
	-$(helm) delete --purge $(TF_VAR_component)-nginx
	-$(helm) delete --purge $(TF_VAR_component)
	@rm -f $(CLOUD_KIND).tf

clean:
	@rm -rf .helm .terraform charts harbor-helm

-include ../../Mk/phonies
