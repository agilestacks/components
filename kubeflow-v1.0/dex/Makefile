.EXPORT_ALL_VARIABLES:
.DEFAULT_GOAL := deploy

jq      := jq -cMr
yq      := yq
RAND    := $(shell uuidgen | tr '[:upper:]' '[:lower:]' | cut -c-4)

HUB_DEX_NAMESPACE := $(firstword $(HUB_DEX_NAMESPACE) kube-system)
kubectl := kubectl --context="$(DOMAIN_NAME)" -o json -n $(HUB_DEX_NAMESPACE)

ifneq ($(PLAIN_PASS),)
HUB_DEX_PASSWD := $(shell htpasswd -bnB -C 12 "" $(PLAIN_PASS)  | tr -d ':\n')
endif

TEMPDIR   := $(shell mkdir -p .cache; mktemp -d .cache/XXXX)
PAYLOAD   := $(TEMPDIR)/config.json
PATCHFILE := $(TEMPDIR)/patch.json

jsonnet := jsonnet 
jsonnet += -V HUB_DEX_USER 
jsonnet += -V HUB_DEX_PASSWD 
jsonnet += -J $(TEMPDIR)

$(PAYLOAD):
	$(kubectl) get configmap dex -o yaml | $(yq) r - 'data[config.yaml]' | $(yq) r -j - > $@

$(PATCHFILE): $(PAYLOAD)
	$(jsonnet) -o $@ patch.jsonnet

patch: $(PATCHFILE)
	$(kubectl) patch configmap/dex --type merge -p='{"data":{"config.yaml": $(shell cat $^)}}'
	$(kubectl) rollout restart deployment/dex

deploy: patch

clean:
	rm -rf .cache

.PHONY: deploy undeploy patch
