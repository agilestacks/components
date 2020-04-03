.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export CHART                ?= stable/nfs-client-provisioner
export COMPONENT_NAME      ?= nfs-client-provisioner
export NAMESPACE           ?= kube-system
export DOMAIN_NAME         ?= kubernetes-admin@kubernetes
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init install sc
.PHONY: deploy

ifeq ($(DEFAULT_STORAGE_CLASS),nfs-client-provisioner)
deploy: sc
endif

ifneq (,$(NFS_MOUNT_OPTIONS))
    SET_MOUNT_OPTIONS := --set 'nfs.mountOptions={ $(shell echo $(NFS_MOUNT_OPTIONS) | sed 's/,/, /g' ) }'
endif

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
          $(SET_MOUNT_OPTIONS)             \
	  --replace                        \
	  --wait
.PHONY: install

sc:
	$(kubectl) apply -f storageclass.yaml
.PHONY: sc

undeploy: init
	$(helm) list --failed --deleted -q | grep -E '^$(COMPONENT_NAME)$$' && \
        $(helm) delete --purge $(COMPONENT_NAME) || exit 0
.PHONY: undeploy

clean:
	rm -rf $(HELM_HOME)

