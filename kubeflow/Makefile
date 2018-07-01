.DEFAULT_GOAL := deploy

export NAMESPACE    		?= kubeflow
export DOMAIN_NAME  		?= default
export COMPONENT_NAME       ?= kubeflow
export kubectl      		?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export KUBEFLOW_VERSION		?=v0.1.3
export ARGO_VERSION			?=v2.1.1
export K8S_API_SPEC			?=v1.9.8
export K8S_API_SERVER		?=
export KF_ENV				?=cloud
export GITHUB_TOKEN			?=


ifneq ($(GITHUB_TOKEN),)
init:
	-$(kubectl) create namespace $(NAMESPACE)
	-ks init kubeflow --namespace=$(NAMESPACE) --server=https://$(K8S_API_SERVER) --dir=kubeflow --api-spec=version:$(K8S_API_SPEC)
.PHONY: init
else
init:
	-$(kubectl) create namespace $(NAMESPACE)
.PHONY: init
endif

ifneq ($(GITHUB_TOKEN),)
install:
	-cd kubeflow && \
	ks registry add kubeflow github.com/kubeflow/kubeflow/tree/$(KUBEFLOW_VERSION)/kubeflow
	-cd kubeflow && \
	ks pkg install kubeflow/core@$(KUBEFLOW_VERSION)
	-cd kubeflow && \
	ks pkg install kubeflow/tf-serving@$(KUBEFLOW_VERSION)
	-cd kubeflow && \
	ks pkg install kubeflow/tf-job@$(KUBEFLOW_VERSION)
	-cd kubeflow && \
	ks pkg install kubeflow/argo@$(KUBEFLOW_VERSION)
	-cd kubeflow && \
	ks pkg install kubeflow/pytorch-job@$(KUBEFLOW_VERSION)
	-cd kubeflow && \
	ks pkg install kubeflow/pachyderm@$(KUBEFLOW_VERSION)
	-cd kubeflow && \
	ks pkg install kubeflow/katib@$(KUBEFLOW_VERSION)
.PHONY: install
else
install:
.PHONY: install
endif

configure:
ifeq ($(GITHUB_TOKEN),)
	-cd kubeflow-v0.2.0-rc.1 && \
	ks generate core kubeflow-core --name=kubeflow-core
	-cd kubeflow-v0.2.0-rc.1 && \
	ks generate argo argo --name=argo
	-cd kubeflow-v0.2.0-rc.1 && \
	ks param set kubeflow-core reportUsage false
	-cd kubeflow-v0.2.0-rc.1 && \
	ks env add $(KF_ENV) --api-spec=version:$(K8S_API_SPEC) --server=https://$(K8S_API_SERVER)
	-cd kubeflow-v0.2.0-rc.1 && \
	ks env set $(KF_ENV) --namespace=$(NAMESPACE)
	-cd kubeflow-v0.2.0-rc.1 && \
	ks param set kubeflow-core cloud aws --env=$(KF_ENV)
	-cd kubeflow-v0.2.0-rc.1 && \
	ks param set kubeflow-core reportUsage false --env=$(KF_ENV)
	-cd kubeflow-v0.2.0-rc.1 && \
	ks param set argo imageTag $(ARGO_VERSION) --env=$(KF_ENV)
else
	-cd kubeflow && \
	ks generate core kubeflow-core --name=kubeflow-core
	-cd kubeflow && \
	ks generate argo argo --name=argo
	-cd kubeflow && \
	ks param set kubeflow-core reportUsage false
	-cd kubeflow && \
	ks env add $(KF_ENV) --api-spec=version:$(K8S_API_SPEC) --server=https://$(K8S_API_SERVER)
	-cd kubeflow && \
	ks env set $(KF_ENV) --namespace=$(NAMESPACE)
	-cd kubeflow && \
	ks param set kubeflow-core cloud aws --env=$(KF_ENV)
	-cd kubeflow && \
	ks param set kubeflow-core reportUsage false --env=$(KF_ENV)
	-cd kubeflow && \
	ks param set argo imageTag $(ARGO_VERSION) --env=$(KF_ENV)
endif
.PHONY: configure


apply:
ifeq ($(GITHUB_TOKEN),)
	-cd kubeflow-v0.2.0-rc.1 && \
	ks apply $(KF_ENV) -c kubeflow-core
	-cd kubeflow-v0.2.0-rc.1 && \
	ks apply $(KF_ENV) -c argo
else
	-cd kubeflow && \
	ks apply $(KF_ENV) -c kubeflow-core
	-cd kubeflow && \
	ks apply $(KF_ENV) -c argo
endif
	-$(kubectl) apply -f ambassador-ingress.yaml
	-$(kubectl) apply -f jupyterhub-ingress.yaml
	-$(kubectl) apply -f argo-ingress.yaml
	-$(kubectl) apply -f centraldashboard-ingress.yaml
.PHONY: apply

deploy: init install configure apply
.PHONY: deploy

undeploy:
	$(kubectl) delete -f ambassador-ingress.yaml | true
	$(kubectl) delete -f jupyterhub-ingress.yaml | true
	$(kubectl) delete -f argo-ingress.yaml | true
	$(kubectl) delete -f centraldashboard-ingress.yaml | true
ifeq ($(GITHUB_TOKEN),)
	cd kubeflow-v0.2.0-rc.1 && \
	ks delete $(KF_ENV) -c kubeflow-core
	-cd kubeflow-v0.2.0-rc.1 && \
	ks delete $(KF_ENV) -c argo
else
	cd kubeflow && \
	ks delete $(KF_ENV) -c kubeflow-core
	-cd kubeflow && \
	ks delete $(KF_ENV) -c argo
endif
.PHONY: undeploy

