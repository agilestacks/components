.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export NAMESPACE    	   ?= etcd-cluster
export COMPONENT_NAME      ?= etcd-cluster
export DOMAIN_NAME         ?= default
export CLUSTER_ENABLED	   ?= false
export BACKUP_ENABLED	   ?= false
export RESTORE_ENABLED	   ?= false
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
export AWS_SECRET_NAME     ?= aws

# for restore verb
export NEW_CLUSTER_NAME      ?= new-etcd-cluster
export NEW_CLUSTER_SIZE      ?= 5
export NEW_CLUSTER_VERSION   ?= 3.2.10
export NEW_CLUSTER_BASEIMAGE ?= gcr.io/etcd-development/etcd
export BACKUP_TO_RESTORE     ?= files.dev-rk.kubernetes.delivery/backup/etcd/etcd-cluster/20171201172909/v1/etcd-cluster/etcd-cluster/3.2.7_0000000000000001_etcd.backup
export TS       	         ?= $(shell date +"%Y%m%d%H%M%S")

deploy: clean init install enable output
.PHONY: deploy

init:
	@mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade

wait_crd:
	@for i in $$(seq 1 60); do \
		if $(kubectl) get customresourcedefinitions/etcdclusters.etcd.database.coreos.com; then \
			sleep 5; \
			exit 0; \
		fi; \
		echo "Waiting for customresourcedefinitions/etcdclusters.etcd.database.coreos.com to be deployed ($$i)..."; \
		sleep 20; \
	done; \
	echo "Timeout waiting for customresourcedefinitions to be deployed" \
	exit 1

backup:
	@./bin/templater.sh ./backup/EtcdBackup.yaml.template | \
	$(kubectl) create -f - && \
	(sleep 3; $(kubectl) get EtcdBackup/$(COMPONENT_NAME)-$(TS) -o json | jq .status)
.PHONY: backup

restore:
	./bin/templater.sh ./restore/EtcdRestore.yaml.template |\
	$(kubectl) create -f -
.PHONY: restore

install:
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install . \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--wait \
			--values values.yaml
.PHONY: install

enable: wait_crd
	$(helm) upgrade \
		--set cluster.enabled=${CLUSTER_ENABLED} \
		--set cluster.backup.enabled=${BACKUP_ENABLED} \
		--set cluster.restore.enabled=${RESTORE_ENABLED} \
		--values values.yaml \
		--namespace $(NAMESPACE) \
		--wait \
		$(COMPONENT_NAME) \
		.
.PHONY: enable

undeploy: init
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
	$(kubectl) get --namespace $(NAMESPACE) EtcdClusters/$(COMPONENT_NAME) -o=yaml|$(kubectl) delete -f - || true
.PHONY: undeploy

clean:
	@rm -rf $(HELM_HOME)
	@rm -rf charts

output:
	# https://github.com/coreos/etcd-operator/pull/1341
	@echo Outputs:
	@echo etcd_url=http://$(COMPONENT_NAME)-client.$(NAMESPACE).svc.cluster.local:2379
	@echo
	@echo etcd has been installed successfully.
.PHONY: output

