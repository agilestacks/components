.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export CHART                ?= stable/nfs-client-provisioner
export COMPONENT_NAME      ?= nfs-client-provisioner
export NAMESPACE           ?= kube-system
export DOMAIN_NAME         ?= kubernetes-admin@kubernetes
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init install
.PHONY: deploy

init:
	mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade --wait
.PHONY: init

install:
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' || \
	$(helm) install $(CHART)           \
	  --namespace=$(NAMESPACE)         \
	  --name $(COMPONENT_NAME)         \
	  --set nfs.server=$(NFS_SERVER)   \
	  --set nfs.path=$(NFS_MOUNT_PATH) \
	  --replace                        \
	  --wait
.PHONY: install

undeploy: init
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' && \
        $(helm) delete --purge $(COMPONENT_NAME) || exit 0
.PHONY: undeploy

clean:
	rm -rf $(HELM_HOME)

