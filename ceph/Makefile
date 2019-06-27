.DEFAULT_GOAL := deploy


KUBECTL_ARGS 		:= --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
kubectl 			?= kubectl $(KUBECTL_ARGS)
export NAMESPACE 	?= rook-ceph
CEPH_DASHBOARD_ROLE ?= admin-no-iscsi
CEPH_DASHBOARD_USER ?= admin
CEPH_DASHBOARD_PASS ?= 12345678
TIMEOUT     		?= 600

deploy: install_ceph config_ceph_dashboard install_nfs

undeploy: uninstall_nfs unistall_ceph  delete_data

install_ceph:
	- $(kubectl) create namespace $(NAMESPACE)
	- $(kubectl) create -f ceph-rbac.yaml
	- $(kubectl) create -f ceph-operator.yaml
	- $(kubectl) create -f ceph-cluster.yaml
	- $(kubectl) create -f ceph-blockdevice.yaml
	- $(kubectl) create -f ceph-toolbox.yaml
	- $(kubectl) create -f ingress.yaml
	- $(MAKE) wait_up

unistall_ceph:
	- $(kubectl) delete -f ingress.yaml
	- $(kubectl) delete -f ceph-blockdevice.yaml
	- $(kubectl) delete -f ceph-toolbox.yaml
	- $(kubectl) delete -f ceph-cluster.yaml
	- $(kubectl) delete -f ceph-operator.yaml
	- $(kubectl) delete ds rook-discover
	- $(kubectl) delete ds rook-ceph-agent
	- $(kubectl) delete -f ceph-rbac.yaml
	- $(MAKE) wait_shutdown

install_nfs:
	- $(kubectl) create -f nfs/ceph-nfs-rbac.yaml
	- $(kubectl) create -f nfs/ceph-nfs-operator.yaml
	- $(kubectl) create -f nfs/ceph-nfs-server.yaml
	- $(kubectl) create -f nfs/ceph-nfs-storageclass.yaml

uninstall_nfs:
	- $(kubectl) delete -f nfs/ceph-nfs-storageclass.yaml
	  # technical debt, the pvc is can't be deleted properly, that's why 'patch'
	- $(kubectl) patch pvc nfs-ceph-claim -p '{"metadata":{"finalizers":null}}'
	- $(kubectl) delete -f nfs/ceph-nfs-server.yaml
	- $(kubectl) delete -f nfs/ceph-nfs-operator.yaml
	- $(kubectl) delete -f nfs/ceph-nfs-rbac.yaml


delete_data:
	- $(kubectl) create -f cleanup.yaml
	sleep 10
	- $(kubectl) delete -f cleanup.yaml

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

wait_up:
	$(eval timeout=$(shell echo "`date +%s` + $(TIMEOUT)" | bc ))
	$(eval get_pod=$(kubectl) get pods --no-headers -l 'app=rook-ceph-osd' --output=jsonpath='{.items..containerStatuses[?(@.ready==true)].containerID}')
	@ echo "Waiting for ceph osd pod up and running [container count: $(count)]"

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