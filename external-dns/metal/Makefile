.DEFAULT_GOAL := deploy

DOMAIN_NAME      ?= $(error DOMAIN_NAME not defined)
NAMESPACE        ?= kube-system
helm             := helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
aws              := aws --output=text
rsync            := rsync -arvp
kubectl          := kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

# This is the one true helm chart (to support aws credentials)
CHART_VERSION    := 2.13.2

export HELM_HOME := $(abspath ..)/.helm
OVERRIDES_DIR    := $(abspath ..)/overrides

CHART_DIR        := $(HELM_HOME)/charts/$(notdir $(CHART_NAME))

deploy:   init install
undeploy: init purge

$(HELM_HOME):
	@ mkdir -p "$@"

init: $(HELM_HOME)
	@ $(helm) init --client-only --upgrade

$(CHART_DIR):
	$(helm) fetch $(CHART_NAME) \
		--version $(CHART_VERSION) \
		--untar \
		--untardir $(dir $@)

purge: $(CHART_DIR)
	# $(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \

	$(helm) delete --purge $(COMPONENT_NAME) || exit 0

install: $(CHART_DIR)
	$(helm) ls -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install $(CHART_DIR) \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--wait \
			--values $(abspath ..)/values.yaml \
			--values $(abspath .)/values-$(PROVIDER).yaml

clean:
	rm -rf $(CHART_DIR)

.PHONY := patch-chart
