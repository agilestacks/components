.DEFAULT_GOAL := deploy

JHUB_NAMESPACE    ?= jhub
NAME              ?= jhub
JHUB_HELM_VERSION ?= 0.7.0
DOMAIN_NAME       ?= dev.kubernetes.delivery

helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(JHUB_NAMESPACE)"

deploy:
	$(helm) init --client-only --upgrade
	$(helm) repo add jupyterhub https://jupyterhub.github.io/helm-chart/
	$(helm) repo update
	$(kubectl) apply -f storageclass.yaml
	$(helm) upgrade --install $(NAME) jupyterhub/jupyterhub \
  		--namespace $(JHUB_NAMESPACE) \
  		--version $(JHUB_HELM_VERSION) \
  		--values config.yaml
	$(kubectl) apply -f operator-config/role.yaml
	$(kubectl) apply -f operator-config/jupyterhubnotebook-crd.yaml

undeploy:
	-$(kubectl) delete -f operator-config/jupyterhubnotebook-crd.yaml
	-$(helm) delete $(NAME) --purge
	-$(kubectl) delete -f storageclass.yaml

-include ../Mk/phonies
