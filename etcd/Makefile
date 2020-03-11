.DEFAULT_GOAL := deploy

export COMPONENT_NAME      ?= etcd-cluster
export DOMAIN_NAME         ?= dev.kubernetes.delivery
export NAMESPACE    	   ?= etcd-cluster
export BACKUP_BUCKET       ?= terraform.agilestacks.com
export ETCD_IMAGE          ?= quay.io/coreos/etcd
export ETCD_VERSION        ?= v3.2.26
export ETCD_CLUSTER_SIZE   ?= 3
export CLUSTER_ENABLED     ?= false
export BACKUP_ENABLED      ?= false
export RESTORE_ENABLED     ?= false
export AWS_SECRET_NAME     ?= awsetcd

export AWS_DEFAULT_REGION  ?= us-east-2
export HELM_HOME           ?= $(shell pwd)/.helm

RESTORE_SNAPSHOT ?=
export TS        := $(shell date +"%Y-%m-%d-%H-%M-%S")

aws     := aws
jq      := jq
kubectl := kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    := helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

running_etcd_pods := $(kubectl) get pods -l app=etcd -o jsonpath='{range.items[?(@.status.containerStatuses[0].ready==true)]}{.kind}{"\n"}{end}'

ifeq ($(RESTORE_SNAPSHOT),)
deploy: clean init purge install enable wait_etcd_pods_initial
else
# restore operator requires seed cluster before restore is initiated
# it seems it doesn't require the cluster to fully stand up
# but we'll wait anyway to isolate restore problem vs generic etcd problem
deploy: CLUSTER_ENABLED:=true
deploy: clean init purge install enable restore wait_etcd_pods_after_restore
endif

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
	echo "Timeout waiting for customresourcedefinitions to be deployed"; \
	exit 1
.PHONY: wait_crd

# the single line output of ... won't flush thru Kubernetes pod log - appears to be stuck to the observer
# at least we have the banner printed
wait_etcd_pods%:
	@if test "$(CLUSTER_ENABLED)" = true; then echo "Waiting for etcd cluster pods to stand up"; \
	for i in $$(seq 1 60); do \
		if test $$($(running_etcd_pods) | wc -l) -eq $(ETCD_CLUSTER_SIZE); then \
			echo "done"; \
			exit 0; \
		fi; \
		echo "still waiting"; \
		sleep 10; \
	done; \
	echo "timeout"; \
	exit 1; fi
.PHONY: wait_etcd_pods%

# after all Makefile and shell/echo acrobatics I can't make --from-literal to insert newline into config= value
backup_config:
	@echo "[default]" > secret-config
	@echo "region = $(BACKUP_REGION)" >> secret-config
	@cat secret-config
	$(kubectl) create secret generic $(AWS_SECRET_NAME) --from-file=config=secret-config
.PHONY: backup_config

unbackup:
	-$(kubectl) delete EtcdBackup/$(COMPONENT_NAME)-$(TS)
	-$(kubectl) delete secret $(AWS_SECRET_NAME)
.PHONY: unbackup

backup: unbackup backup_config
	./bin/templater.sh ./backup/EtcdBackup.yaml.template | $(kubectl) create -f -
	$(eval crd:=EtcdBackup/$(COMPONENT_NAME)-$(TS))
	$(eval get_crd:=$(kubectl) get $(crd) -o json)
	@ echo "Waiting for $(crd)"
	@ for i in $$(seq 60); do \
		if test "$$($(get_crd) | jq -r '.status.succeeded')" != null; then \
			echo "done"; \
			break; \
		fi; \
		echo "still waiting"; \
		sleep 2; \
	done;

	@ $(get_crd) | jq .
	@ test "$$( $(get_crd) | jq -r '.status.succeeded' )" = true
	@ echo Outputs:
	@ echo component.etcd.snapshot = $$( $(get_crd) | jq -r '.spec.s3.path' )
	@ echo

restore_config:
	$(eval SNAPSHOT_REGION=$(shell $(aws) s3api get-bucket-location --bucket \
		$$(echo $(RESTORE_SNAPSHOT) | sed -e 's|/.*||') | $(jq) -r '.LocationConstraint//"us-east-1"'))
	@echo "[default]\nregion = $(SNAPSHOT_REGION)" > secret-config
	$(kubectl) create secret generic $(AWS_SECRET_NAME) --from-file=config=secret-config
.PHONY: restore_config

unrestore:
	-$(kubectl) delete EtcdRestore/$(COMPONENT_NAME)
	-$(kubectl) delete secret $(AWS_SECRET_NAME)
.PHONY: unrestore

restore: wait_etcd_pods_seed unrestore restore_config
	./bin/templater.sh ./restore/EtcdRestore.yaml.template | \
		$(kubectl) create -f -
	$(eval crd:=EtcdRestore/$(COMPONENT_NAME))
	$(eval get_crd:=$(kubectl) get $(crd) -o json)
	@ echo "Waiting for $(crd)"
	@ for i in $$(seq 60); do \
		if test "$$($(get_crd) | jq -r '.status.succeeded')" != null; then \
			echo "done"; \
			break; \
		fi; \
		echo "still waiting"; \
		sleep 5; \
	done;

	@ $(get_crd) | jq .
	@ test "$$( $(get_crd) | jq -r '.status.succeeded' )" = "true"
	@ sleep 10

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

install:
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install . \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--wait \
			--values values.yaml

enable: wait_crd
	$(helm) upgrade \
		--set customResources.createEtcdClusterCRD=${CLUSTER_ENABLED} \
		--set customResources.createBackupCRD=${BACKUP_ENABLED} \
		--set customResources.createRestoreCRD=${RESTORE_ENABLED} \
		--values values.yaml \
		--namespace $(NAMESPACE) \
		--wait \
		$(COMPONENT_NAME) \
		.

uncluster:
	-$(kubectl) get EtcdClusters/$(COMPONENT_NAME) -o=yaml | $(kubectl) delete -f - && \
		sleep 5
.PHONY: uncluster

undeploy: init unrestore uncluster
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

connect:
	$(kubectl) run --rm -ti \
		--env ETCDCTL_API=3 --env ETCDCTL_ENDPOINTS=http://$(COMPONENT_NAME)-client:2379 \
		etcd-shell --image $(ETCD_IMAGE) --restart=Never -- /bin/sh

clean:
	@rm -rf $(HELM_HOME) charts

-include ../Mk/phonies
