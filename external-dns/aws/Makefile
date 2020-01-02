.DEFAULT_GOAL := deploy

COMPONENT_NAME   ?= external-dns
DOMAIN_NAME      ?= $(error DOMAIN_NAME not defined)
NAMESPACE        ?= kube-system
helm             := helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
aws              := aws --output=text
rsync            := rsync -arvp
kubectl          := kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

export HELM_HOME := $(abspath ..)/.helm
export PATH      := $(abspath ..)/bin:$(PATH)
HACK_DIR         := $(abspath ..)/hack

CHART_NAME       ?= stable/external-dns
CHART_DIR        := $(HELM_HOME)/cache/$(notdir $(CHART_NAME))
ROLE_ARN         := $(shell aws-role-by-tag \
							--filter "$(CLUTER_NAME)" \
							--tag superhub.io/role/kind=worker \
							--tag superhub.io/stack/$(DOMAIN_NAME))

ifeq ($(ROLE_ARN),)
$(error cannot find role tags: superhub.io/stack/$(DOMAIN_NAME) and superhub.io/role/kind=worker)
endif

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

patch-chart: $(CHART_DIR)
	$(rsync) --exclude-from='$(HACK_DIR)/.cpignore' $(HACK_DIR)/ $<

purge: $(CHART_DIR)
	# $(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \

	$(helm) delete --purge $(COMPONENT_NAME) || exit 0

install: patch-chart
	# $(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \

	- $(helm) install $(CHART_DIR) \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--wait \
			--values $(abspath .)/values.yaml \
			--set aws.assumeRoleArn=$(ROLE_ARN)

clean:
	rm -rf $(CHART_DIR)

.PHONY := patch-chart
