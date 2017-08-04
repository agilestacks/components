.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export NAMESPACE    	   	 ?= etcd-cluster
export COMPONENT_NAME      ?= etcd-cluster
export DOMAIN_NAME         ?= default
export CLUSTER_ENABLED	   ?= false
export BACKUP_ENABLED	   ?= false
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"


deploy: clean init fetch wait install enable output
.PHONY: deploy

init:
	@mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade
	@mkdir -p charts

wait:
	@for i in $$(seq 1 60); do \
		if $(helm) version; then \
			exit 0; \
		fi; \
		echo "Waiting for Tiller pod is up and running ($$i)..."; \
		sleep 10; \
	done; \
	echo "Timeout waiting for Tiller" \
	exit 1

wait_tpr:
	@for i in $$(seq 1 60); do \
		if $(kubectl) get thirdpartyresources/cluster.etcd.coreos.com; then \
			exit 0; \
		fi; \
		echo "Waiting for thirdpartyresource/cluster.etcd.coreos.com to be deployed ($$i)..."; \
		sleep 20; \
	done; \
	echo "Timeout waiting for thirdpartyresource to be deployed" \
	exit 1

fetch:
	$(helm) fetch \
		--destination charts \
		--untar stable/etcd-operator
.PHONY: fetch

install:
ifeq ($(findstring $(COMPONENT_NAME), $(shell $(helm) list -q | xargs)),)
	$(helm) install charts/etcd-operator \
		--name $(COMPONENT_NAME) \
		--namespace $(NAMESPACE) \
		--replace \
		--wait \
		--values values.yaml
endif
.PHONY: install
enable: wait_tpr
	$(helm) upgrade \
		--set cluster.enabled=${CLUSTER_ENABLED} \
		--set cluster.backup.enabled=${BACKUP_ENABLED} \
		--values values.yaml \
		--namespace $(NAMESPACE) \
		--wait \
		$(COMPONENT_NAME) \
		charts/etcd-operator
.PHONY: enable

undeploy: init
	$(kubectl) get --namespace $(NAMESPACE) cluster/$(COMPONENT_NAME) -o=yaml|$(kubectl) delete -f -
	$(helm) delete --purge $(COMPONENT_NAME)
.PHONY: undeploy

clean:
	@rm -rf $(HELM_HOME)
	@rm -rf charts

output:
	@echo Outputs:
	@echo etcd_url=http://$(COMPONENT_NAME)-client.$(NAMESPACE).svc.cluster.local:2379
	@echo etcd has been installed successfully.
.PHONY: output

