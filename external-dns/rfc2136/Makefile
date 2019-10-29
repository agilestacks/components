.DEFAULT_GOAL := deploy

export NAMESPACE    ?= kube-system
DOMAIN_NAME         ?= $(TF_VAR_domain_name)
CLOUD_KIND          ?= metal

KUBECONFIG := kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy: purge apply install

ifneq (,$(filter $(CLOUD_KIND), metal))
	$(shell echo comencing metal installation)
else
	$(error cloud.kind / CLOUD_KIND must be either aws or hybrid)
endif


$(TF_DATA_DIR):
	@mkdir -p $@

init: $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
        $(STATE_BACKEND_CONFIG)

purge:
	-$(KUBECONFIG) delete -f deployment.yaml

install:
	$(KUBECONFIG) apply -f ../manifests.yaml
	$(KUBECONFIG) apply -f deployment.yaml

undeploy: purge

-include ../Mk/phonies
