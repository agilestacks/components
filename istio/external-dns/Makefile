.DEFAULT_GOAL := deploy

jq      := jq -cMr
kubectl := kubectl --context="$(DOMAIN_NAME)" -o json

EXTERNALDNS_NAMESPACE := $(firstword $(EXTERNALDNS_NAMESPACE) kube-system)
EXTERNALDNS_LABEL     := $(firstword $(EXTERNALDNS_LABEL) app.kubernetes.io/name=external-dns)
EXTERNALDNS_DEPL      := $(shell $(kubectl) -n "$(EXTERNALDNS_NAMESPACE)" \
						get deployment -l "$(EXTERNALDNS_LABEL)" \
						| $(jq) '.items?[0].metadata.name | select (.!=null)')
ifeq (,$(EXTERNALDNS_DEPL))
	$(warning Searching deployment with label: $(EXTERNALDNS_LABEL))
	$(error Deployment not found in namespace $(EXTERNALDNS_NAMESPACE))
endif

# PATCH := $(shell cat $(abspath patch.json) | $(jq) .)


EXTERNALDNS_IMAGE := $(firstword $(EXTERNALDNS_IMAGE) docker.io/bitnami/external-dns:0.5.17-debian-9-r50)
ISTIO_NAMESPACE   := $(firstword $(ISTIO_NAMESPACE) istio-system)

ifeq ($(ISTIO_GW_SVC),)
ISTIO_GW_SVC:=$(shell $(kubectl) -n $(ISTIO_NAMESPACE) get svc -l istio=ingressgateway \
	| $(jq) '.items?[0].metadata.name | select (.!=null)')
endif

TEMPDIR := $(shell mktemp -d $(abspath .tmp-XXXXXX))
PAYLOAD := $(TEMPDIR)/deployment.json
PATCH   := $(TEMPDIR)/patch.json

jsonnet := jsonnet
jsonnet += -V EXTERNALDNS_IMAGE 
jsonnet += -V ISTIO_NAMESPACE 
jsonnet += -V ISTIO_GW_SVC

export EXTERNALDNS_IMAGE ISTIO_NAMESPACE ISTIO_GW_SVC

$(PAYLOAD):
	@ mkdir -p "$(@D)"
	$(kubectl) -n "$(EXTERNALDNS_NAMESPACE)" get deployment $(EXTERNALDNS_DEPL) > $@

$(PATCH): $(PAYLOAD)
	$(jsonnet) patch.jsonnet -J "$(dir $^)" -o $@

patch: $(PATCH)
	$(kubectl) -n $(EXTERNALDNS_NAMESPACE) \
		patch deployment $(EXTERNALDNS_DEPL) \
		--type='json' -p='$(shell $(jq) < $^)'

deploy: clean patch

clean:
	@ rm -rf .tmp-*

.PHONY: deploy undeploy patch
