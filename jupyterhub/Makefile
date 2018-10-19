.DEFAULT_GOAL := deploy

JHUB_NAMESPACE ?= jhub
NAME ?= jhub
JHUB_HELM_VERSION ?= 0.7.0
DOMAIN_NAME ?=

helm ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(JHUB_NAMESPACE)"

deploy:
	$(helm) repo add jupyterhub https://jupyterhub.github.io/helm-chart/
	$(helm) repo update
	$(kubectl) apply -f storageclass.yaml
	$(helm) upgrade --install $(NAME) jupyterhub/jupyterhub \
  		--namespace $(JHUB_NAMESPACE) \
  		--version $(JHUB_HELM_VERSION) \
  		--values config.yaml
.PHONY: deploy	

undeploy:
	-$(helm) delete $(NAME) --purge
	-$(kubectl) delete -f storageclass.yaml
.PHONY: undeploy
