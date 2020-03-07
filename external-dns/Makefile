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

$(HELM_HOME):
	@ mkdir -p "$@"

init: $(HELM_HOME) $(CHART_DIR)
	@ $(helm) init --client-only --upgrade

HELM_OPTS += --values $(abspath values.yaml)
ifneq ($(ISTIO_GATEWAY),)
HELM_OPTS += --set 'sources=$(shell $(yq) read -j values.yaml | $(jq) '.sources + ["istio-gateway"] | unique')'
endif

$(CHART_DIR): $(PROVIDER)
	rm -rf $@
	$(helm) fetch $(CHART_NAME) \
		--version $(shell cat $</chart-version.txt 2>/dev/null || echo $(CHART_VERSION)) \
		--untar --untardir $(dir $@)
	$(rsync) --exclude-from='overrides/.cpignore' overrides/ $@

purge:
	- $(helm) delete --purge $(COMPONENT_NAME)

$(PROVIDER):
	$(error Provider: $@ is not yet supported)

install: $(PROVIDER)
	make -C "$<" $@

deploy:   init install
undeploy: init purge

.PHONY: deploy purge undeploy install init $(CHART_DIR)
.EXPORT_ALL_VARIABLES: install 
