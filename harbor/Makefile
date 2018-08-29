.DEFAULT_GOAL := deploy

STATE_BUCKET   ?= terraform.agilestacks.com
STATE_REGION   ?= us-west-1

export TF_OPTS            ?= -no-color
export TF_UPDATE          ?= -update
export TF_CLI_ARGS        ?=
export TF_DATA_DIR        ?= .terraform

export HELM_HOME ?= $(shell pwd)/.helm

NGINX_CHART ?= stable/nginx-ingress
NGINX_CHART_VERSION ?= 0.1.1

export TF_VAR_nginx_service_name ?= nginx-nginx-ingress-controller

terraform ?= terraform-v0.11
helm ?= helm --kube-context="$(TF_VAR_domain_name)" --tiller-namespace="$(TF_VAR_namespace)"
kubectl ?= kubectl --context="$(TF_VAR_domain_name)" --namespace="$(TF_VAR_namespace)"
git ?= git

init:
	- $(kubectl) create namespace $(TF_VAR_namespace)
	@mkdir -p charts
	$(terraform) init -get=true -force-copy $(CLI_ARGS) \
        -backend=true -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(TF_VAR_domain_name)/s3-bucket/$(TF_VAR_component)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"
.PHONY: init	

harbor: 
	$(helm) init --client-only --upgrade --wait
	$(git) clone https://github.com/goharbor/harbor-helm
	$(helm) dependency update harbor-helm
	$(helm)	install harbor-helm \
	    --name $(TF_VAR_component) \
		--namespace $(TF_VAR_namespace) \
		--replace \
		--wait \
		-f values-harbor.yaml
.PHONY: harbor

nginx:
	$(helm) fetch \
		--destination charts \
		--untar $(NGINX_CHART) \
		--version $(NGINX_CHART_VERSION)
	$(helm) install charts/$(notdir $(NGINX_CHART)) \
		--name nginx \
		--namespace $(TF_VAR_namespace) \
		--replace \
		--wait \
		--values values-nginx.yaml \
		--version $(NGINX_CHART_VERSION)		
.PHONY: nginx

plan:
	$(terraform) plan $(TF_OPTS) -refresh=true -module-depth=-1 -out=.terraform/terraform.tfplan
.PHONY: plan

apply:
	$(terraform) apply $(TF_OPTS) -auto-approve .terraform/terraform.tfplan
.PHONY: apply	

zone:
	$(MAKE) plan
	$(MAKE) apply
.PHONY: zone

deploy: init harbor nginx zone

undeploy: init
	TF_OPTS=-destroy
	$(MAKE) plan
	$(MAKE) apply
	$(helm) delete --purge nginx
	$(helm) delete --purge $(TF_VAR_component)
.PHONY: undeploy

