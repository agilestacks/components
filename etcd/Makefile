.DEFAULT_GOAL := deploy

export AWS_DEFAULT_REGION  ?= us-east-2
export HELM_HOME           ?= $(shell pwd)/.helm
export NAMESPACE    	   ?= etcd-cluster
export COMPONENT_NAME      ?= etcd-cluster
export TF_VAR_name         ?= test
export TF_VAR_base_domain  ?= kubernetes.delivery
export DOMAIN_NAME         ?= $(TF_VAR_name).$(TF_VAR_base_domain)
export BACKUP_BUCKET       ?= us-east-2
export ETCD_IMAGE          ?= quay.io/coreos/etcd
export ETCD_VERSION        ?= 3.2.17
export ETCD_CLUSTER_SIZE   ?= 3
export CLUSTER_ENABLED     ?= false
export BACKUP_ENABLED      ?= false
export RESTORE_ENABLED     ?= false
export AWS_SECRET_NAME     ?= awsetcd

export RESTORE_SNAPSHOT    ?= $(BACKUP_BUCKET)/backup/$(DOMAIN_NAME)/etcd/$(COMPONENT_NAME)/latest
export TS       	       := $(shell date +"%Y-%m-%d-%H-%M-%S")

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

running_pods := $(kubectl) get pods -l app=etcd -o jsonpath='{range.items[?(@.status.containerStatuses[0].ready==true)]}{.kind}{"\n"}{end}'

ifeq ($(RESTORE_SNAPSHOT),)
deploy: clean init install enable wait_pods
else
deploy: clean init install enable restore
endif
.PHONY: deploy

init:
	@mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade
.PHONY: init

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
.PHONY: wait_crd

wait_pods:
	@printf "Waiting for cluster pods to be running"; \
	for i in $$(seq 1 60); do \
		if [ $$($(running_pods) | wc -l) -eq $(ETCD_CLUSTER_SIZE) ] ; then \
			printf "\ndone\n"; \
			exit 0; \
		fi; \
		printf "."; \
		sleep 20; \
	done; \
	printf "\nTimeout Error\n" \
	exit 1
.PHONY: wait_pods

# after all Makefile and shell/echo acrobatics I can't make --from-literal to insert newline into config= value
awsetcd:
	#$(HUB) render secret-config.template
	-$(kubectl) create secret generic $(AWS_SECRET_NAME) --from-file=config=secret-config
.PHONY: awsetcd

unbackup:
	-$(kubectl) delete EtcdBackup/$(COMPONENT_NAME)-$(TS)
.PHONY: unbackup

backup: unbackup awsetcd
	$(eval get_crd=$(kubectl) get EtcdBackup/$(COMPONENT_NAME)-$(TS))
	./bin/templater.sh ./backup/EtcdBackup.yaml.template | $(kubectl) create -f - && \
		(sleep 5; $(get_crd) -o yaml)
	`$(get_crd)
	$(eval success=$(shell $(get_crd) -o json | jq -r .status.succeeded))
	$(eval snapshot=$(shell $(get_crd) -o json | jq -r .spec.s3.path))

	test "$(success)" = "true"
	@ echo Outputs:
	@ echo component.etcd.snapshot = $(snapshot)
	@ echo
.PHONY: backup

unrestore:
	-$(kubectl) delete EtcdRestore/$(COMPONENT_NAME)
.PHONY: unrestore

restore: wait_pods unrestore awsetcd
	./bin/templater.sh ./restore/EtcdRestore.yaml.template | \
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
		--set customResources.createEtcdClusterCRD=${CLUSTER_ENABLED} \
		--set customResources.createBackupCRD=${BACKUP_ENABLED} \
		--set customResources.createRestoreCRD=${RESTORE_ENABLED} \
		--values values.yaml \
		--namespace $(NAMESPACE) \
		--wait \
		$(COMPONENT_NAME) \
		.
.PHONY: enable

uncluster:
	-$(kubectl) get EtcdClusters/$(COMPONENT_NAME) -o=yaml | $(kubectl) delete -f - && \
		sleep 5
.PHONY: uncluster

undeploy: init unrestore uncluster
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
.PHONY: undeploy

connect:
	$(kubectl) run --rm -ti \
		--env ETCDCTL_API=3 --env ETCDCTL_ENDPOINTS=http://$(COMPONENT_NAME)-client:2379 \
		etcd-shell --image $(ETCD_IMAGE) --restart=Never -- /bin/sh
.PHONY: connect

clean:
	@rm -rf $(HELM_HOME)
	@rm -rf charts
.PHONY: clean
