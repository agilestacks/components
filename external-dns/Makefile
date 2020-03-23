.DEFAULT_GOAL := deploy
export HELM_HOME := $(abspath .helm)
CHART_DIR        := $(HELM_HOME)/charts/$(notdir $(CHART_NAME))
DOMAIN_NAME      ?= $(error DOMAIN_NAME not defined)
NAMESPACE        ?= kube-system
jq               := jq -cM
yq               := yq
helm             := helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
aws              := aws --output=text
rsync            := rsync -arvp
kubectl          := kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
COMPONENT_NAME   ?= $(error COMPONENT_NAME cannot be empty)
CHART_VERSION    ?= 2.20.6
$(HELM_HOME):
	@ mkdir -p "$@"

init: $(HELM_HOME)
	@ $(helm) init --client-only --upgrade
	@ $(helm) repo add bitnami https://charts.bitnami.com/bitnami

HELM_OPTS += --values $(abspath values.yaml)
ifneq (,$(filter istio,$(HUB_PROVIDES)))
HELM_OPTS += --set 'sources=$(shell $(yq) read -j values.yaml | $(jq) '.sources + ["istio-gateway"] | unique')'
HELM_OPTS += --set 'istioIngressGateways=["$(ISTIO_NAMESPACE)/$(ISTIO_GATEWAY)"]'
endif

$(CHART_DIR):
	rm -rf $@
	$(helm) fetch $(CHART_NAME) \
		--version $(CHART_VERSION) \
		--untar --untardir $(dir $@)
	$(rsync) --exclude-from='overrides/.cpignore' overrides/ $@

purge:
	- $(helm) delete --purge $(COMPONENT_NAME)

$(PROVIDER):
	$(helm) ls -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		make -C "$@" install

deploy:   init $(CHART_DIR) $(PROVIDER)
undeploy: init purge

.PHONY: deploy purge undeploy $(PROVIDER) init $(CHART_DIR)
.EXPORT_ALL_VARIABLES: $(PROVIDER)
