.DEFAULT_GOAL := deploy

export TF_VAR_namespace    	?= kubeflow
export TF_VAR_component    	?= kubeflow
export TF_VAR_domain_name  	?= dev.kubernetes.delivery
export TF_VAR_url_prefix	?= svc
export kubectl      		?= kubectl --context="$(TF_VAR_domain_name)" --namespace="$(TF_VAR_namespace)"
export KUBEFLOW_VERSION		?= v0.3.2
export KUBEFLOW_KS_DIR	    ?= ks-app
export ARGO_VERSION			?= v2.2.1
export AMBASSADOR_VERSION   ?= quay.io/datawire/ambassador:0.40.1
export K8S_API_SPEC			?= v1.11.4
export K8S_API_SERVER		?=
export KF_ENV				?= cloud


terraform ?= terraform-v0.11
STATE_BUCKET ?= terraform.agilestacks.com
STATE_REGION ?= us-east-1
ACM_CERTIFICATE_ARN ?=

ifneq (,$(ACM_CERTIFICATE_ARN))
	PROTOCOL=https
else
	PROTOCOL=http
endif

deploy: clean init fetch configure install get plan apply output

init:
	@mkdir -p .terraform
	$(terraform) init $(TF_OPTS) \
		-get=true -reconfigure -force-copy  \
		-backend=true -input=false \
		-backend-config="bucket=$(STATE_BUCKET)" \
		-backend-config="region=$(STATE_REGION)" \
		-backend-config="key=$(TF_VAR_domain_name)/kubeflow/$(TF_VAR_component)/terraform.tfstate" \
		-backend-config="profile=$(AWS_PROFILE)" \
		./aws
	-$(kubectl) create namespace $(TF_VAR_namespace)
	-ks init kubeflow --context=$(TF_VAR_domain_name) --namespace=$(TF_VAR_namespace) --dir=$(KUBEFLOW_KS_DIR) --api-spec=version:$(K8S_API_SPEC)
.PHONY: init

fetch:
	-cd $(KUBEFLOW_KS_DIR) && \
	ks env rm default
	-cd $(KUBEFLOW_KS_DIR) && \
	ks registry add kubeflow ../kubeflow-$(KUBEFLOW_VERSION)/kubeflow
	-cd $(KUBEFLOW_KS_DIR) && \
	ks pkg install kubeflow/argo
	-cd $(KUBEFLOW_KS_DIR) && \
	ks pkg install kubeflow/core
	-cd $(KUBEFLOW_KS_DIR) && \
	ks pkg install kubeflow/examples
	-cd $(KUBEFLOW_KS_DIR) && \
	ks pkg install kubeflow/katib
	-cd $(KUBEFLOW_KS_DIR) && \
	ks pkg install kubeflow/mpi-job
	-cd $(KUBEFLOW_KS_DIR) && \
	ks pkg install kubeflow/pytorch-job
	-cd $(KUBEFLOW_KS_DIR) && \
	ks pkg install kubeflow/seldon
	-cd $(KUBEFLOW_KS_DIR) && \
	ks pkg install kubeflow/tf-serving
.PHONY: fetch

configure:
	-cd $(KUBEFLOW_KS_DIR) && \
	ks generate argo argo
	-cd $(KUBEFLOW_KS_DIR) && \
	ks generate ambassador ambassador
	-cd $(KUBEFLOW_KS_DIR) && \
	ks generate jupyterhub jupyterhub
	-cd $(KUBEFLOW_KS_DIR) && \
	ks generate centraldashboard centraldashboard
	-cd $(KUBEFLOW_KS_DIR) && \
	ks generate tf-job-operator tf-job-operator
	-cd $(KUBEFLOW_KS_DIR) && \
	ks generate pytorch-operator pytorch-operator
	-cd $(KUBEFLOW_KS_DIR) && \
	ks generate katib katib
	-cd $(KUBEFLOW_KS_DIR) && \
	ks generate seldon seldon
	-cd $(KUBEFLOW_KS_DIR) && \
	ks generate tf-serving tf-serving
	-cd $(KUBEFLOW_KS_DIR) && \
	ks env add $(KF_ENV) --api-spec=version:$(K8S_API_SPEC) --context=$(TF_VAR_domain_name)
	-cd $(KUBEFLOW_KS_DIR) && \
	ks env set $(KF_ENV) --namespace=$(TF_VAR_namespace)
	-cd $(KUBEFLOW_KS_DIR) && \
	ks param set spartakus reportUsage false --env=$(KF_ENV)
	-cd $(KUBEFLOW_KS_DIR) && \
	ks param set argo imageTag $(ARGO_VERSION) --env=$(KF_ENV)
	-cd $(KUBEFLOW_KS_DIR) && \
	ks param set ambassador ambassadorImage $(AMBASSADOR_VERSION) --env=$(KF_ENV)
	-cd $(KUBEFLOW_KS_DIR) && \
	ks param set ambassador ambassadorServiceType LoadBalancer --env=$(KF_ENV)
	-cd $(KUBEFLOW_KS_DIR) && \
	ks param set ambassador ambassadorProtocol $(PROTOCOL) --env=$(KF_ENV)
	-cd $(KUBEFLOW_KS_DIR) && \
	ks param set ambassador ambassadorAcmCertificateArn $(ACM_CERTIFICATE_ARN) --env=$(KF_ENV)
	-cd $(KUBEFLOW_KS_DIR) && \
	ks param set ambassador cloud aws --env=$(KF_ENV)
.PHONY: configure


install:
	-$(kubectl) apply -f default-storage-class.yaml
	-cd $(KUBEFLOW_KS_DIR) && \
	ks apply $(KF_ENV) -c ambassador --context=$(TF_VAR_domain_name)
	-cd $(KUBEFLOW_KS_DIR) && \
	ks apply $(KF_ENV) -c jupyterhub --context=$(TF_VAR_domain_name)
	-cd $(KUBEFLOW_KS_DIR) && \
	ks apply $(KF_ENV) -c centraldashboard --context=$(TF_VAR_domain_name)
	-cd $(KUBEFLOW_KS_DIR) && \
	ks apply $(KF_ENV) -c tf-job-operator --context=$(TF_VAR_domain_name)
	-cd $(KUBEFLOW_KS_DIR) && \
	ks apply $(KF_ENV) -c pytorch-operator --context=$(TF_VAR_domain_name)
	-cd $(KUBEFLOW_KS_DIR) && \
	ks apply $(KF_ENV) -c argo --context=$(TF_VAR_domain_name)
	-cd $(KUBEFLOW_KS_DIR) && \
	ks apply $(KF_ENV) -c katib --context=$(TF_VAR_domain_name)
	-cd $(KUBEFLOW_KS_DIR) && \
	ks apply $(KF_ENV) -c seldon --context=$(TF_VAR_domain_name)
#	-cd $(KUBEFLOW_KS_DIR) && \
#	ks apply $(KF_ENV) -c tf-serving --context=$(TF_VAR_domain_name)
	-$(kubectl) delete -f bootstrapper-rbac.yaml
	-$(kubectl) create -f bootstrapper-rbac.yaml
	-$(kubectl) create -f bootstrapper-install.yaml
	-$(kubectl) create -f oidc-crd.yaml
	-$(kubectl) create secret generic ambassador-auth-jwt-key --from-literal=jwt-key=qafBTgd27hg0cX11tawDLu0SLsXXiiEW4kl6SC5p4eBwRCr0ejiSBDSdW8mQQwFh2nS0wOXtdWq28DvxEnIFaQ==
	-$(kubectl) create secret generic ambassador-auth-redis-password --from-literal=redis-password=MH2POuA75acYSvm5RvpOJsAJINI=
	-$(kubectl) create secret generic ambassador-auth-oidc-provider --from-literal=oidc-provider=$(PROTOCOL)://auth.$(TF_VAR_domain_name)
	-$(kubectl) create secret generic ambassador-auth-self-url --from-literal=self-url=$(PROTOCOL)://$(TF_VAR_url_prefix).$(TF_VAR_domain_name)/
	-$(kubectl) create secret generic ambassador-auth-client-id --from-literal=client-id=kubeflow-client
	-$(kubectl) create secret generic ambassador-auth-client-secret --from-literal=client-secret=345t6dfgdfg4-57yDSDfjeuDVQEW
	-$(kubectl) create -f oidc-deployment.yaml
	-$(kubectl) create -f oidc-ambassador-service.yaml
.PHONY: install

get:
	$(terraform) get $(TF_UPDATE) ./aws
.PHONY: get

plan:
	$(terraform) plan $(TF_OPTS) -refresh=true -module-depth=-1 -out=.terraform/terraform.tfplan ./aws
.PHONY: plan

apply:
	$(terraform) apply $(TF_OPTS) -Xshadow=false .terraform/terraform.tfplan
	@echo
.PHONY: apply

destroy: TF_OPTS:=-destroy
destroy: plan

undeploy: init destroy apply fetch configure uninstall

uninstall:
	-$(kubectl) create -f bootstrapper-rbac.yaml | true
	-$(kubectl) create -f bootstrapper-uninstall.yaml | true
	-cd $(KUBEFLOW_KS_DIR) && \
	ks delete $(KF_ENV) -c ambassador --context=$(TF_VAR_domain_name)
	-cd $(KUBEFLOW_KS_DIR) && \
	ks delete $(KF_ENV) -c jupyterhub --context=$(TF_VAR_domain_name)
	-cd $(KUBEFLOW_KS_DIR) && \
	ks delete $(KF_ENV) -c centraldashboard --context=$(TF_VAR_domain_name)
	-cd $(KUBEFLOW_KS_DIR) && \
	ks delete $(KF_ENV) -c tf-job-operator --context=$(TF_VAR_domain_name)
	-cd $(KUBEFLOW_KS_DIR) && \
	ks delete $(KF_ENV) -c pytorch-operator --context=$(TF_VAR_domain_name)
	-cd $(KUBEFLOW_KS_DIR) && \
	ks delete $(KF_ENV) -c argo --context=$(TF_VAR_domain_name)
	-cd $(KUBEFLOW_KS_DIR) && \
	ks delete $(KF_ENV) -c katib --context=$(TF_VAR_domain_name)
	-cd $(KUBEFLOW_KS_DIR) && \
	ks delete $(KF_ENV) -c seldon --context=$(TF_VAR_domain_name)
	-cd $(KUBEFLOW_KS_DIR) && \
	ks delete $(KF_ENV) -c tf-serving --context=$(TF_VAR_domain_name)
	-cd $(KUBEFLOW_KS_DIR) && \
	ks env rm $(KF_ENV)
	-$(kubectl) delete pvc --all | true
	-$(kubectl) delete -f default-storage-class.yaml | true
	-$(kubectl) delete -f oidc-crd.yaml | true
	-$(kubectl) delete -f oidc-deployment.yaml
	-$(kubectl) delete -f oidc-ambassador-service.yaml | true
	-$(kubectl) delete secret generic ambassador-auth-jwt-key | true
	-$(kubectl) delete secret ambassador-auth-redis-password | true
	-$(kubectl) delete secret ambassador-auth-oidc-provider | true
	-$(kubectl) delete secret ambassador-auth-self-url | true
	-$(kubectl) delete secret ambassador-auth-client-id | true
	-$(kubectl) delete secret ambassador-auth-client-secret | true
.PHONY: uninstall

clean:
	rm -rf .terraform/modules .terraform/plugins $(KUBEFLOW_KS_DIR)
.PHONY: clean

output:
	@echo
	@echo Outputs:
	@echo ingress_protocol = $(PROTOCOL)
	@echo
.PHONY: output
