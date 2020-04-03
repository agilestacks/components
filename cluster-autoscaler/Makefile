.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= cluster-autoscaler
DOMAIN_NAME    ?= test.dev.superhub.io
NAMESPACE      ?= kube-system

AUTOSCALER_1.14_VERSION := v1.14.7
AUTOSCALER_1.15_VERSION := v1.15.5
AUTOSCALER_1.16_VERSION := v1.16.4
AUTOSCALER_1.17_VERSION := v1.17.1
AUTOSCALER_1.18_VERSION := v1.18.0

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
