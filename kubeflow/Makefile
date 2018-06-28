.DEFAULT_GOAL := deploy

export NAMESPACE    		?= kubeflow
export DOMAIN_NAME  		?= default
export COMPONENT_NAME       ?= kubeflow
export kubectl      		?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export ks					?= ks --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export KUBEFLOW_VERSION		?=v0.1.3
export K8S_API_SPEC			?=v1.9.8
export KF_ENV				?=cloud


init:
	-$(ks) init kubeflow --dir=$(COMPONENT_NAME) --api-spec=version:$(K8S_API_SPEC)
	-$(kubectl) create namespace $(NAMESPACE)
.PHONY: init

install:
	-cd $(COMPONENT_NAME) && \
	ks registry add kubeflow github.com/kubeflow/kubeflow/tree/$(KUBEFLOW_VERSION)/kubeflow
	-cd $(COMPONENT_NAME) && \
	ks pkg install kubeflow/core@$(KUBEFLOW_VERSION)
	-cd $(COMPONENT_NAME) && \
	ks pkg install kubeflow/tf-serving@$(KUBEFLOW_VERSION)
	-cd $(COMPONENT_NAME) && \
	ks pkg install kubeflow/tf-job@$(KUBEFLOW_VERSION)
.PHONY: install

configure:
	-cd $(COMPONENT_NAME) && \
	ks generate core kubeflow-core --name=kubeflow-core
	-cd $(COMPONENT_NAME) && \
	ks generate pytorch-operator pytorch-operator
	-cd $(COMPONENT_NAME) && \
	ks param set kubeflow-core reportUsage false
	-cd $(COMPONENT_NAME) && \
	ks env add $(KF_ENV) --api-spec=version:$(K8S_API_SPEC)
	-cd $(COMPONENT_NAME) && \
	ks param set kubeflow-core cloud aws --env=$(KF_ENV)
	-cd $(COMPONENT_NAME) && \
	ks param set kubeflow-core reportUsage false --env=$(KF_ENV)
	-cd $(COMPONENT_NAME) && \
	ks env set $(KF_ENV) --namespace=$(NAMESPACE)
.PHONY: configure

apply:
	-cd $(COMPONENT_NAME) && \
	$(ks) apply $(KF_ENV) -c kubeflow-core
.PHONY: apply

deploy: init install configure apply
.PHONY: deploy

undeploy:
	cd $(COMPONENT_NAME) && \
	$(ks) delete $(KF_ENV) -c kubeflow-core
.PHONY: undeploy

