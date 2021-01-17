.DEFAULT_GOAL := deploy

HELM_HOME   := $(abspath .helm)
CHART_NAME  := istio
CHART_DIR   := $(HELM_HOME)/charts/$(notdir $(CHART_NAME))
export HELM_HOME

ISTIO_VERSION ?= 1.5.0
NAMESPACE     ?= istio-system

GLOBAL_VALUES := $(HELM_HOME)/values-global.yaml
DEFAULT_VALUES := $(HELM_HOME)/values-defaults.yaml

kubectl   := kubectl --context="$(DOMAIN_NAME)"
helm      := helm2 --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
HELM_OPTS += --values $(GLOBAL_VALUES)
HELM_OPTS += --values $(DEFAULT_VALUES)
HELM_OPTS += --values $(abspath values.yaml)

deploy: $(CHART_DIR) $(GLOBAL_VALUES) $(DEFAULT_VALUES)
	$(kubectl) get namespace $(NAMESPACE) || \
		$(kubectl) create namespace $(NAMESPACE)
	$(helm) --namespace $(NAMESPACE) ls -q | grep -E '^$(COMPONENT_NAME)$$' \
	|| $(helm) install $(CHART_DIR)/charts/gateways \
		--name $(COMPONENT_NAME) \
		--namespace $(NAMESPACE) \
		--wait $(HELM_OPTS)

undeploy: $(CHART_DIR)
	$(helm) ls -q -a | grep -E '^$(COMPONENT_NAME)$$' \
		&& $(helm) delete --purge $(COMPONENT_NAME) \
		|| echo "release $(COMPONENT_NAME) already deleted"

$(HELM_HOME):
	mkdir -p $@
	$(helm) init --client-only --upgrade --wait

$(GLOBAL_VALUES): $(CHART_DIR)
	yq e '{"global": .global}' $</values.yaml > $@

$(DEFAULT_VALUES): $(CHART_DIR)
	yq e '{"$(COMPONENT_NAME)": .istio-ingressgateway}' $</charts/gateways/values.yaml > $@

$(CHART_DIR): $(HELM_HOME)
	$(helm) repo add istio https://storage.googleapis.com/istio-release/releases/$(ISTIO_VERSION)/charts/
	test -d "$@" || \
		$(helm) fetch istio/istio --debug \
			--version=$(CHART_VERSION) \
			--untar --untardir $(dir $@)
	rsync -aIv $(abspath ext)/ $@/charts/gateways/templates

.SILENT: undeploy $(HELM_HOME)
.IGNORE: undeploy namespace
# .INTERMEDIATE: $(GLOBAL_VALUES) $(DEFAULT_VALUES)
.PHONY: deploy undeploy $(HELM_HOME)
