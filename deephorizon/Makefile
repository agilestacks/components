.DEFAULT_GOAL := deploy

export COMPONENT_NAME ?= deephorizon
export NAMESPACE      ?= deephorizon
REGISTRY              ?= agilestacks

docker       := docker
kubectl      := kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

manifests := $(wildcard manifests/*.yaml)
manifests := $(filter-out manifests/namespace.yaml manifests/serviceaccount.yaml manifests/clusterrole.yaml, $(manifests))

configmap := $(shell python3 unflatten.py | yq r - | tr '\n' '^' | tr -d '\r')

deploy: purge prepare apply

prepare:
	yq w manifests/configmap.yaml.part data.config "$$(echo "$(configmap)" | tr '^' '\n ')" > manifests/configmap.yaml
	$(kubectl) apply -f manifests/namespace.yaml
	$(kubectl) apply -f manifests/serviceaccount.yaml
	$(kubectl) apply -f manifests/clusterrole.yaml

apply: $(manifests)
	@for f in $?; do $(kubectl) apply -f $${f}; done

undeploy: purge

purge:
	-$(kubectl) delete namespace $(NAMESPACE)
	-$(kubectl) delete clusterrole deephorizon


