.DEFAULT_GOAL := deploy

STATE_BUCKET ?= terraform.agilestacks.com
STATE_REGION ?= us-east-1

export TF_VAR_domain             ?= dev.kubernetes.delivery
export TF_VAR_component 		 ?= harbor
export TF_VAR_namespace          ?= harbor
export TF_VAR_pull_secret ?= $(TF_VAR_component)-pull-secret

export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(TF_VAR_domain)-$(TF_VAR_component)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log

export HELM_HOME ?= $(shell pwd)/.helm
export CLOUD_KIND  ?= aws
export STORAGE_KIND ?= s3

NGINX_CHART          ?= stable/nginx-ingress
NGINX_CHART_VERSION  ?= 0.26.0
HARBOR_CHART_VERSION ?= 1.0.0

terraform   ?= terraform-v0.11
TF_CLI_ARGS ?= -no-color -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan

helm    ?= helm --kube-context="$(TF_VAR_domain)" --tiller-namespace="kube-system"
kubectl ?= kubectl --context="$(TF_VAR_domain)" --namespace="$(TF_VAR_namespace)"
git     ?= git

deploy: init harbor init-tf plan-tf apply-tf

undeploy: init-tf destroy-tf apply-tf delete	

$(HELM_HOME):
	mkdir -p $@

namespace:
	-$(kubectl) create namespace $(TF_VAR_namespace)

init: namespace
	@rm -rf harbor-helm
	@mkdir -p charts

harbor: $(HELM_HOME)
	$(helm) list --deleted --failed -q --namespace $(TF_VAR_namespace) | grep -E '^$(TF_VAR_component)$$' && \
		$(helm) delete --purge $(TF_VAR_component) || exit 0	
	-$(kubectl) create -f aws-storage-class.yaml
	$(helm) init --client-only --upgrade --wait
	-$(git) clone --depth 1 -b $(HARBOR_CHART_VERSION) https://github.com/goharbor/harbor-helm $(HELM_HOME)/harbor
	$(helm) dependency update $(HELM_HOME)/harbor
	$(helm) list -q --namespace $(TF_VAR_namespace) | grep -E '^$(TF_VAR_component)$$' || \
		$(helm)	install $(HELM_HOME)/harbor \
		    --name $(TF_VAR_component) \
			--namespace $(TF_VAR_namespace) \
			--wait \
			--version $(HARBOR_CHART_VERSION) \
			--values $(STORAGE_KIND)/values-harbor.yaml
	$(kubectl) apply -f ingress.yaml
	$(kubectl) apply -f ingress-notary.yaml		
.PHONY: harbor


$(TF_DATA_DIR):
	@rm -rf $@ && mkdir -p $@

init-tf: $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(TF_VAR_domain)/harbor/$(TF_VAR_component)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"

plan-tf:
	$(terraform) plan $(TF_CLI_ARGS) -refresh=true -module-depth=-1 -out=$(TFPLAN)

apply-tf:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)

refresh:
	$(terraform) refresh $(TF_CLI_ARGS)

destroy-tf: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy-tf: plan-tf

delete: 
	-$(kubectl) delete -f ingress-notary.yaml	
	-$(kubectl) delete -f ingress.yaml
	-$(helm) delete --purge $(TF_VAR_component)
	@rm -f $(CLOUD_KIND).tf

clean:
	@rm -rf .helm .terraform charts harbor-helm

-include ../../Mk/phonies
