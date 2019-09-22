.DEFAULT_GOAL := deploy

export TF_VAR_namespace    	?= kubeflow
export TF_VAR_component    	?= kubeflow
export TF_VAR_domain_name  	?= dev.kubernetes.delivery
export TF_VAR_url_prefix	?= svc
export KUBEFLOW_VERSION		?= v0.3.4
export KUBEFLOW_KS_DIR	    ?= ks-app
export ARGO_VERSION			?= v2.2.1
export AMBASSADOR_VERSION   ?= quay.io/datawire/ambassador:0.40.2
export PIPELINE_VERSION		?= 0.1.19
export K8S_API_SPEC			?= v1.13.5
export K8S_API_SERVER		?=
export KF_ENV				?= cloud
export TF_DATA_DIR          := .terraform

SELDON_APISERVER ?= seldon-seldon-apiserver

kubectl := kubectl --context="$(TF_VAR_domain_name)" --namespace="$(TF_VAR_namespace)"
terraform := terraform-v0.11
ks := cd $(KUBEFLOW_KS_DIR) && ks
jq := jq -cM

STATE_BUCKET ?= terraform.agilestacks.com
STATE_REGION ?= us-east-1
ACM_CERTIFICATE_ARN ?=
PROTOCOL ?= https
TIMEOUT ?= 600
AMBASSADOR_SERVICE := ambassador

deploy: clean init fetch configure install get plan wait_elb apply output

namespace:
	- $(kubectl) create namespace $(TF_VAR_namespace)

$(TF_DATA_DIR):
	mkdir -p $@

$(KUBEFLOW_KS_DIR): namespace
	- ks init kubeflow --context=$(TF_VAR_domain_name) --namespace=$(TF_VAR_namespace) --dir=$@

init: $(TF_DATA_DIR) $(KUBEFLOW_KS_DIR)
	$(terraform) init $(TF_OPTS) \
		-get=true -reconfigure -force-copy  \
		-backend=true -input=false \
		-backend-config="bucket=$(STATE_BUCKET)" \
		-backend-config="region=$(STATE_REGION)" \
		-backend-config="key=$(TF_VAR_domain_name)/kubeflow/$(TF_VAR_component)/terraform.tfstate" \
		-backend-config="profile=$(AWS_PROFILE)" \
		./aws

fetch:
	- $(ks) env rm default
	- $(ks) registry add kubeflow "$(shell pwd)/kubeflow-$(KUBEFLOW_VERSION)/kubeflow"
	- $(ks) pkg install kubeflow/argo
	- $(ks) pkg install kubeflow/common
	- $(ks) pkg install kubeflow/jupyter
	- $(ks) pkg install kubeflow/metacontroller
	- $(ks) pkg install kubeflow/examples
	- $(ks) pkg install kubeflow/katib
	- $(ks) pkg install kubeflow/mpi-job
	- $(ks) pkg install kubeflow/pytorch-job
	- $(ks) pkg install kubeflow/pipeline
	- $(ks) pkg install kubeflow/seldon
	- $(ks) pkg install kubeflow/tf-training

configure:
	- $(ks) generate argo argo
	- $(ks) generate ambassador ambassador
	- $(ks) generate metacontroller metacontroller
	- $(ks) generate jupyter jupyter
	- $(ks) generate jupyter-web-app jupyter-web-app
	- $(ks) generate notebook-controller notebook-controller
	- $(ks) generate centraldashboard centraldashboard
	- $(ks) generate pytorch-operator pytorch-operator
	- $(ks) generate katib katib
	## ERROR Invalid value: \"Cluster\": ExternalTrafficPolicy can only be set on NodePort and LoadBalancer service"
	- $(ks) generate seldon seldon \
		--withApife true \
		--apifeServiceType ClusterIP \
		--externalTrafficPolicy="" \
		--withAmbassador false
	- $(ks) generate tf-job-operator tf-job-operator
	- $(ks) generate pipeline pipeline
	- $(ks) env add $(KF_ENV) --context=$(TF_VAR_domain_name)
	- $(ks) env set $(KF_ENV) --namespace=$(TF_VAR_namespace)
	- $(ks) param set spartakus reportUsage false --env=$(KF_ENV)
	- $(ks) param set argo imageTag $(ARGO_VERSION) --env=$(KF_ENV)
	- $(ks) param set ambassador ambassadorImage $(AMBASSADOR_VERSION) --env=$(KF_ENV)
	- $(ks) param set ambassador ambassadorServiceType LoadBalancer --env=$(KF_ENV)
	- $(ks) param set ambassador ambassadorProtocol $(PROTOCOL) --env=$(KF_ENV)
	- $(ks) param set ambassador ambassadorAcmCertificateArn $(ACM_CERTIFICATE_ARN) --env=$(KF_ENV)
	- $(ks) param set ambassador platform aws --env=$(KF_ENV)
	- $(ks) param set jupyter-web-app image gcr.io/kubeflow-images-public/jupyter-web-app:v-latest-base-fcb983-1126234591183507456
	- $(ks) param set jupyter-web-app injectIstio false --env=$(KF_ENV)
	- $(ks) param set --env=$(KF_ENV) pipeline apiImage gcr.io/ml-pipeline/api-server:$(PIPELINE_VERSION)
	- $(ks) param set --env=$(KF_ENV) pipeline scheduledWorkflowImage gcr.io/ml-pipeline/scheduledworkflow:$(PIPELINE_VERSION)
	- $(ks) param set --env=$(KF_ENV) pipeline persistenceAgentImage gcr.io/ml-pipeline/persistenceagent:$(PIPELINE_VERSION)
	- $(ks) param set --env=$(KF_ENV) pipeline viewerCrdControllerImage gcr.io/ml-pipeline/viewer-crd-controller:$(PIPELINE_VERSION)
	- $(ks) param set --env=$(KF_ENV) pipeline uiImage gcr.io/ml-pipeline/frontend:$(PIPELINE_VERSION)
install:
	- $(ks) apply $(KF_ENV) -c ambassador --context=$(TF_VAR_domain_name)
	- $(ks) apply $(KF_ENV) -c metacontroller --context=$(TF_VAR_domain_name)
	- $(ks) apply $(KF_ENV) -c jupyter --context=$(TF_VAR_domain_name)
	- $(ks) apply $(KF_ENV) -c jupyter-web-app --context=$(TF_VAR_domain_name)
	- $(ks) apply $(KF_ENV) -c notebook-controller --context=$(TF_VAR_domain_name)
	- $(ks) apply $(KF_ENV) -c centraldashboard --context=$(TF_VAR_domain_name)
	- $(ks) apply $(KF_ENV) -c pytorch-operator --context=$(TF_VAR_domain_name)
	- $(ks) apply $(KF_ENV) -c argo --context=$(TF_VAR_domain_name)
	- $(ks) apply $(KF_ENV) -c katib --context=$(TF_VAR_domain_name)
	- $(ks) apply $(KF_ENV) -c seldon --context=$(TF_VAR_domain_name)
	- $(ks) apply $(KF_ENV) -c pipeline --context=$(TF_VAR_domain_name)
	- $(ks) apply $(KF_ENV) -c tf-job-operator --context=$(TF_VAR_domain_name)
	- $(kubectl) create -f oidc-crd.yaml
	- $(kubectl) create secret generic ambassador-auth-jwt-key --from-literal=jwt-key=qafBTgd27hg0cX11tawDLu0SLsXXiiEW4kl6SC5p4eBwRCr0ejiSBDSdW8mQQwFh2nS0wOXtdWq28DvxEnIFaQ==
	- $(kubectl) create secret generic ambassador-auth-redis-password --from-literal=redis-password=MH2POuA75acYSvm5RvpOJsAJINI=
	- $(kubectl) create secret generic ambassador-auth-oidc-provider --from-literal=oidc-provider=$(PROTOCOL)://auth.$(TF_VAR_domain_name)
	- $(kubectl) create secret generic ambassador-auth-self-url --from-literal=self-url=$(PROTOCOL)://$(TF_VAR_url_prefix).$(TF_VAR_domain_name)/
	- $(kubectl) create secret generic ambassador-auth-client-id --from-literal=client-id=kubeflow-client
	- $(kubectl) create secret generic ambassador-auth-client-secret --from-literal=client-secret=345t6dfgdfg4-57yDSDfjeuDVQEW
	- $(kubectl) create -f oidc-deployment.yaml
	- $(kubectl) create -f oidc-ambassador-service.yaml
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
	- $(kubectl) create -f bootstrapper-rbac.yaml | true
	- $(kubectl) create -f bootstrapper-uninstall.yaml | true
	- $(ks) delete $(KF_ENV) -c ambassador --context=$(TF_VAR_domain_name)
	- $(ks) delete $(KF_ENV) -c metacontroller --context=$(TF_VAR_domain_name)
	- $(ks) delete $(KF_ENV) -c jupyter --context=$(TF_VAR_domain_name)
	- $(ks) delete $(KF_ENV) -c jupyter-web-app --context=$(TF_VAR_domain_name)
	- $(ks) delete $(KF_ENV) -c notebook-controller --context=$(TF_VAR_domain_name)
	- $(ks) delete $(KF_ENV) -c centraldashboard --context=$(TF_VAR_domain_name)
	- $(ks) delete $(KF_ENV) -c pytorch-operator --context=$(TF_VAR_domain_name)
	- $(ks) delete $(KF_ENV) -c argo --context=$(TF_VAR_domain_name)
	- $(ks) delete $(KF_ENV) -c katib --context=$(TF_VAR_domain_name)
	- $(ks) delete $(KF_ENV) -c seldon --context=$(TF_VAR_domain_name)
	- $(ks) delete $(KF_ENV) -c pipeline --context=$(TF_VAR_domain_name)
	- $(ks) delete $(KF_ENV) -c tf-job-operator --context=$(TF_VAR_domain_name)
	- $(ks) env rm $(KF_ENV)
	- $(kubectl) delete pvc --all | true
	- $(kubectl) delete -f oidc-crd.yaml | true
	- $(kubectl) delete -f oidc-deployment.yaml
	- $(kubectl) delete -f oidc-ambassador-service.yaml | true
	- $(kubectl) delete secret generic ambassador-auth-jwt-key | true
	- $(kubectl) delete secret ambassador-auth-redis-password | true
	- $(kubectl) delete secret ambassador-auth-oidc-provider | true
	- $(kubectl) delete secret ambassador-auth-self-url | true
	- $(kubectl) delete secret ambassador-auth-client-id | true
	- $(kubectl) delete secret ambassador-auth-client-secret | true

clean:
	rm -rf $(TF_DATA_DIR)/modules $(TF_DATA_DIR)/plugins $(KUBEFLOW_KS_DIR)

output:
	@echo
	@echo Outputs:
	@echo protocol = $(PROTOCOL)
	@echo

wait_elb:
	$(eval timeout=$(shell echo "`date +%s` + $(TIMEOUT)" | bc ))
	$(eval get_svc=$(kubectl) get --output=json service $(AMBASSADOR_SERVICE))
	@ echo 'Waiting for $(AMBASSADOR_SERVICE) service elb'
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
