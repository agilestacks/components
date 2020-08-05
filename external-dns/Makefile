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

HELM_OPTS := --set 'txtOwnerId=$(firstword $(shell md5sum <<<"$(DOMAIN_NAME)"))'
HELM_OPTS += --values $(abspath values.yaml)
ifneq (,$(filter istio,$(HUB_PROVIDES)))
HELM_OPTS += --set 'sources=$(shell \
	$(yq) read -j values.yaml | \
	$(jq) -r '.sources + ["istio-gateway"] | unique | "{"+join(",")+"}"'\
)'
endif

ifneq (,DOMAIN_FILTERS)
HELM_OPTS += --set 'domainFilters={$(subst $(space),$(comma),$(foreach d,$(DOMAIN_FILTERS),$(d)))}'
endif


$(CHART_DIR):
	rm -rf $@
	$(helm) fetch $(CHART_NAME) \
		--version $(CHART_VERSION) \
		--untar --untardir $(dir $@)
	$(rsync) --exclude-from='overrides/.cpignore' overrides/ $@

deploy: init $(CHART_DIR)
	make -C "$(PROVIDER)" deploy

undeploy: init
	make -C "$(PROVIDER)" undeploy

.PHONY: deploy purge undeploy init $(CHART_DIR)
.EXPORT_ALL_VARIABLES: deploy undeploy
