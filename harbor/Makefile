.DEFAULT_GOAL := deploy

STATE_BUCKET   ?= terraform.agilestacks.com
STATE_REGION   ?= us-west-1

export TF_OPTS            ?= -no-color
export TF_UPDATE          ?= -update
export TF_CLI_ARGS        ?=
export TF_DATA_DIR        ?= .terraform

export HELM_HOME ?= $(shell pwd)/.helm

NGINX_CHART ?= stable/nginx-ingress
NGINX_CHART_VERSION ?= 0.26.0
HARBOR_CHART_VERSION ?= 0.2.0
TIMEOUT     ?= 600

export TF_VAR_nginx_service_name ?= nginx-nginx-ingress-controller

terraform ?= terraform-v0.11
helm ?= helm --kube-context="$(TF_VAR_domain_name)" --tiller-namespace="kube-system"
kubectl ?= kubectl --context="$(TF_VAR_domain_name)" --namespace="$(TF_VAR_namespace)"
git ?= git

init:
	-$(kubectl) create namespace $(TF_VAR_namespace)
	@rm -rf harbor-helm
	@mkdir -p charts
	@mkdir -p .terraform
.PHONY: init

harbor:
	$(helm) init --client-only --upgrade --wait
	$(git) clone https://github.com/goharbor/harbor-helm
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
	$(helm) list -q --namespace $(TF_VAR_namespace) | grep -E '^nginx$$' || \
		$(helm) install charts/$(notdir $(NGINX_CHART)) \
			--name nginx \
			--namespace $(TF_VAR_namespace) \
			--wait \
			--version $(NGINX_CHART_VERSION) \
			--values values-nginx.yaml
.PHONY: nginx

plan:
	$(terraform) init -get=true -force-copy $(CLI_ARGS) \
        -backend=true -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(TF_VAR_domain_name)/harbor/$(TF_VAR_component)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"
	$(terraform) plan $(TF_OPTS) -refresh=true -module-depth=-1 -out=.terraform/terraform.tfplan
.PHONY: plan

apply:
	$(terraform) apply $(TF_OPTS) -auto-approve .terraform/terraform.tfplan
.PHONY: apply

zone:
	$(MAKE) plan
	$(MAKE) apply
.PHONY: zone

clean:
	@rm -rf .helm
	@rm -rf .terraform
	@rm -rf charts
	@rm -rf harbor-helm
.PHONY: clean

deploy: init harbor nginx zone

undeploy:
	-$(MAKE) plan TF_OPTS="$(TF_OPTS) -destroy"
	-$(MAKE) apply
	-$(helm) delete --purge nginx
	-$(helm) delete --purge $(TF_VAR_component)
.PHONY: undeploy
