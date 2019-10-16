.DEFAULT_GOAL := deploy


KUBECTL_ARGS 		:= --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
COMPONENT_NAME      ?= rook-ceph
HELM_REPO           ?= https://charts.rook.io/release
HELM_PROJECT 		?= rook-release
HELM_CHART 			?= rook-ceph
CHART_VERSION		?= v1.1.1
CEPH_DASHBOARD_ROLE ?= admin-no-iscsi
CEPH_DASHBOARD_USER ?= admin
CEPH_DASHBOARD_PASS ?= 12345678
TIMEOUT     		?= 600
export NAMESPACE 	?= rook-ceph
export HELM_HOME ?= $(shell pwd)/.helm

helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
kubectl 			?= kubectl $(KUBECTL_ARGS)

deploy: clean init fetch purge install_ceph config_ceph_crushmap config_ceph_dashboard install_nfs

undeploy:  uninstall_nfs unistall_ceph delete_data

init:
	@mkdir -p $(HELM_HOME) charts
	$(helm) init --client-only --upgrade
	$(helm) repo add $(HELM_PROJECT) $(HELM_REPO)
	$(helm) repo update

fetch:
	$(helm) fetch \
	  --destination charts \
	  --untar $(HELM_PROJECT)/$(HELM_CHART) \
	  --version $(CHART_VERSION)

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
	  $(kubectl) -n $(NAMESPACE) delete secret --all && \
	  $(helm) delete --purge $(COMPONENT_NAME) || exit 0

install_ceph:
	- $(kubectl) delete $(CEPH_SC) default
	- $(kubectl) create namespace $(NAMESPACE)
	- $(helm) install charts/$(notdir $(HELM_CHART)) \
		--namespace $(NAMESPACE) \
		--replace \
		--wait \
		--name $(COMPONENT_NAME) \
		--set agent.flexVolumeDirPath=$(FLEX_VOL_PATH)
	- $(kubectl) create -f ceph-cluster.yaml
	- $(kubectl) create -f ceph-blockdevice.yaml
	- $(kubectl) patch sc $(CEPH_SC) -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
	- $(kubectl) create -f ceph-toolbox.yaml
	- $(kubectl) create -f ingress.yaml
	- @ echo "If Ceph boots for the first time on a cluster - it can take up to 5-10min to start"
	- $(MAKE) wait_up

install_nfs:
	- $(kubectl) create -f nfs/ceph-nfs-rbac.yaml
	- $(kubectl) create -f nfs/ceph-nfs-operator.yaml
	- $(kubectl) create -f nfs/ceph-nfs-pvc.yaml && sleep 15
	- $(MAKE) wait_pvc_bound
	- $(kubectl) create -f nfs/ceph-nfs-server.yaml
	- $(kubectl) create -f nfs/ceph-nfs-storageclass.yaml

unistall_ceph:
	- $(kubectl) delete -f ingress.yaml
	- $(kubectl) delete -f ceph-blockdevice.yaml
	- $(kubectl) delete -f ceph-toolbox.yaml
	- $(kubectl) delete deploy csi-cephfsplugin-provisioner
	- $(kubectl) delete deploy csi-rbdplugin-provisioner	
	- $(kubectl) delete ds csi-cephfsplugin
	- $(kubectl) delete ds csi-rbdplugin
	- $(kubectl) delete ds rook-ceph-agent
	- $(kubectl) delete ds rook-discover
	- $(kubectl) delete -f ceph-cluster.yaml
	- $(helm) delete --purge $(COMPONENT_NAME)

	- $(MAKE) wait_shutdown

uninstall_nfs:
	- $(kubectl) delete -f nfs/ceph-nfs-server.yaml && sleep 5
	- $(kubectl) delete -f nfs/ceph-nfs-pvc.yaml && sleep 5
	- $(kubectl) get pv | grep pv | cut -d' ' -f1 | xargs -I% $(kubectl) delete pv %
	- $(kubectl) delete -f nfs/ceph-nfs-storageclass.yaml
	- $(kubectl) delete -f nfs/ceph-nfs-operator.yaml
	- $(kubectl) delete -f nfs/ceph-nfs-rbac.yaml && sleep 5


delete_data:
	- $(kubectl) create -f cleanup.yaml && sleep 10
	- $(kubectl) delete -f cleanup.yaml
	- $(kubectl) delete $(CEPH_SC) default

config_ceph_crushmap:
	@ echo "Configuring CEPH crush map for kernel version 4"
	$(eval ceph_toolbox=$(shell $(kubectl) get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}'))
	- $(kubectl) exec -i $(ceph_toolbox) -- bash -c "ceph osd crush tunables hammer"

config_ceph_dashboard:
	@ echo "Configure CEPH dashboard"
	$(eval ceph_toolbox=$(shell $(kubectl) get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}'))
	- $(kubectl) exec -i $(ceph_toolbox) -- bash -c "ceph dashboard ac-role-create $(CEPH_DASHBOARD_ROLE)"
	@ for scope in dashboard-settings log rgw prometheus grafana nfs-ganesha manager hosts rbd-image config-opt rbd-mirroring cephfs user osd pool monitor; do \
		$(kubectl) exec -i $(ceph_toolbox) -- bash -c "ceph dashboard ac-role-add-scope-perms $(CEPH_DASHBOARD_ROLE) $${scope} create delete read update"; \
	done
	- $(kubectl) exec -i $(ceph_toolbox) -- bash -c "ceph dashboard ac-user-set-roles admin $(CEPH_DASHBOARD_ROLE)"
	- $(kubectl) exec -i $(ceph_toolbox) -- bash -c "ceph dashboard ac-user-set-password $(CEPH_DASHBOARD_USER) $(CEPH_DASHBOARD_PASS)"

ceph_tools:
	- $(kubectl) exec -it $(shell $(kubectl) get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') bash

wait_pvc_bound:
	$(eval timeout=$(shell echo "`date +%s` + $(TIMEOUT)" | bc ))
	$(eval get_pvc=$(kubectl) get pvc --no-headers -l 'pvc-name=nfs-ceph-claim' --output=jsonpath='{.items..spec.volumeName}')
	@ echo "Waiting for blockdevice pvc to be bound"

	@ while [ `date +%s` -le "$(timeout)" ]; do \
		if [[ `$(get_pvc) | wc -w | xargs` -ge 1 ]]; then \
			echo " done"; \
			exit 0; \
		fi; \
		printf "."; \
		sleep 8; \
	done; \
	echo " ERROR timeout $(TIMEOUT)sec"; \
	exit 1

wait_up:
	$(eval timeout=$(shell echo "`date +%s` + $(TIMEOUT)" | bc ))
	$(eval get_pod=$(kubectl) get pods --no-headers -l 'app=rook-ceph-osd' --output=jsonpath='{.items..containerStatuses[?(@.ready==true)].containerID}')
	@ echo "Waiting for ceph osd pod up and running [container count: 1]"

	@ while [ `date +%s` -le "$(timeout)" ]; do \
		if [[ `$(get_pod) | wc -w | xargs` -ge 1 ]]; then \
			echo " done"; \
			exit 0; \
		fi; \
		printf "."; \
		sleep 8; \
	done; \
	echo " ERROR timeout $(TIMEOUT)sec"; \
	exit 1

wait_shutdown:
	$(eval timeout=$(shell echo "`date +%s` + $(TIMEOUT)" | bc ))
	$(eval get_pod=$(kubectl) get pods --no-headers -l 'app=rook-ceph-agent' --output=json)
	@ echo "Waiting for ceph manager pod to terminate"

	@ while [ `date +%s` -le "$(timeout)" ]; do \
		if [[ -z `$(get_pod) | jq -c '.items[].spec.containers'` ]]; then \
			echo " done"; \
			exit 0; \
		fi; \
		printf "."; \
		sleep 8; \
	done; \
	echo " ERROR timeout $(TIMEOUT)sec"; \
	exit 1

clean:
	rm -rf $(HELM_HOME) $(notdir $(HELM_CHART))