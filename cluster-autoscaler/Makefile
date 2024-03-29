.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= cluster-autoscaler
DOMAIN_NAME    ?= test.dev.superhub.io
NAMESPACE      ?= kube-system

AUTOSCALER_1.14_VERSION := v1.14.8
AUTOSCALER_1.15_VERSION := v1.15.6
AUTOSCALER_1.16_VERSION := v1.16.7
AUTOSCALER_1.17_VERSION := v1.17.4
AUTOSCALER_1.18_VERSION := v1.18.3
AUTOSCALER_1.19_VERSION := v1.19.2
AUTOSCALER_1.20_VERSION := v1.20.1
AUTOSCALER_1.21_VERSION := v1.21.1
AUTOSCALER_1.22_VERSION := v1.22.1

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy: kube_version:=$(shell $(kubectl) version -o json | jq -r '.serverVersion | .major + "." + .minor' | sed -e 's/[^0-9.]//g')
deploy:
	$(kubectl) apply -f rbac.yaml
	$(kubectl) apply -f service-account.yaml
	$(kubectl) apply -f pod-disruption-budget.yaml
	cat deployment.yaml | \
		sed -E -e 's/(image: .*cluster-autoscaler:).*/\1$(AUTOSCALER_$(kube_version)_VERSION)/' | \
		$(kubectl) apply -f -

undeploy:
	-$(kubectl) delete -f deployment.yaml
	-$(kubectl) delete -f pod-disruption-budget.yaml
	-$(kubectl) delete -f service-account.yaml
	-$(kubectl) delete -f rbac.yaml

-include ../Mk/phonies
