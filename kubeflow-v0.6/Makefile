.DEFAULT_GOAL := deploy

export KUBEFLOW_NS	    	?= kubeflow
export TF_VAR_namespace    	?= istio-system
export TF_VAR_component    	?= kubeflow
export TF_VAR_domain_name  	?= test.dev.superhub.io
export TF_VAR_url_prefix	?= svc
export KUBEFLOW_DIR	    	?= kubeflow-app
export KUBEFLOW_COMMIT		?= 3e85b3c83de12fed7d675151d0d4f8474eb04790
export TF_DATA_DIR          := .terraform
export TF_VAR_kubeconfig_context ?= $(TF_VAR_domain_name)

kubectl := kubectl --context="$(TF_VAR_domain_name)" --namespace="$(TF_VAR_namespace)"
terraform := terraform-v0.11
kfctl := cd $(KUBEFLOW_DIR) && kfctl
jq := jq -cM

STATE_BUCKET ?= terraform.agilestacks.com
STATE_REGION ?= us-east-1
ACM_CERTIFICATE_ARN ?=
PROTOCOL ?= https
TIMEOUT ?= 600
ISTIO_SERVICE := istio-ingressgateway

deploy: clean init fetch configure install get plan wait_elb apply output

$(TF_DATA_DIR):
	mkdir -p $@

init:
	$(terraform) init $(TF_OPTS) \
		-get=true -reconfigure -force-copy  \
		-backend=true -input=false \
		-backend-config="bucket=$(STATE_BUCKET)" \
		-backend-config="region=$(STATE_REGION)" \
		-backend-config="key=$(TF_VAR_domain_name)/kubeflow-v0.6/$(TF_VAR_component)/terraform.tfstate" \
		-backend-config="profile=$(AWS_PROFILE)" \
		./aws

fetch:
	rm -rf $(KUBEFLOW_DIR)
	- kfctl init $(KUBEFLOW_DIR) --config=$(shell pwd)/kfctl_aws.yaml -V
	cp -r asi/ $(KUBEFLOW_DIR)/.cache/manifests/manifests-$(KUBEFLOW_COMMIT)/asi/

configure:
	- $(kfctl) generate k8s -V

install:
	- $(kfctl) apply k8s -V
.PHONY: install

get:
	$(terraform) get $(TF_UPDATE) ./aws
.PHONY: get

plan:
	- $(terraform) plan $(TF_OPTS) -refresh=true -module-depth=-1 -out=.terraform/terraform.tfplan ./aws

apply:
	$(terraform) apply $(TF_OPTS) -Xshadow=false .terraform/terraform.tfplan
	@echo

destroy: init
	$(MAKE) plan TF_OPTS=-destroy
	- $(MAKE) apply

undeploy:  destroy fetch configure uninstall

uninstall:
	- $(kfctl) delete k8s -V

clean:
	rm -rf $(TF_DATA_DIR)/modules $(TF_DATA_DIR)/plugins $(KUBEFLOW_DIR)

output:
	@echo
	@echo Outputs:
	@echo protocol = $(PROTOCOL)
	@echo

wait_elb:
	$(eval timeout=$(shell echo "`date +%s` + $(TIMEOUT)" | bc ))
	$(eval get_svc=$(kubectl) get --output=json service $(ISTIO_SERVICE))
	@ echo 'Waiting for $(ISTIO_SERVICE) service elb'
	@ while [ `date +%s` -le "$(timeout)" ]; do \
		if [ `$(get_svc) | $(jq) '.status.loadBalancer.ingress' | xargs` != "null" ]; then \
			printf ' done\n---\n'; \
			$(get_svc) | jq .status.loadBalancer;\
			test `$(get_svc) | $(jq) '.status.loadBalancer.ingress' | xargs` != "null" && exit 0; \
		fi; \
		printf "."; \
		sleep 2; \
	done; \
	echo " ERROR timeout $(TIMEOUT)sec"; \
	exit 1

-include ../Mk/phonies
