.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= nvidia-driver
DOMAIN_NAME    ?= dev.kubernetes.delivery
NAMESPACE      ?= kube-system

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy: purge install

purge:
	-$(kubectl) delete -f k8s-device-plugin-nvidia-daemonset.yaml
	-$(kubectl) delete -f nvidia-driver-install-daemonset.yaml

install:
	$(kubectl) apply -f k8s-device-plugin-nvidia-daemonset.yaml
	$(kubectl) apply -f nvidia-driver-install-daemonset.yaml

undeploy: purge

-include ../Mk/phonies
