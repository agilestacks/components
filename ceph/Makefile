.DEFAULT_GOAL := deploy

export NAMESPACE ?= rook-ceph
KUBECTL_ARGS := --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
kubectl ?= kubectl $(KUBECTL_ARGS)
CEPH_DASHBOARD_ROLE ?= admin-no-iscsi
CEPH_DASHBOARD_USER ?= admin
CEPH_DASHBOARD_PASS ?= 12345678

deploy: install configure_storage config_dashboard

install:
	- $(kubectl) create namespace $(NAMESPACE)
	- $(kubectl) create -f rbac.yaml
	- $(kubectl) create -f ceph-operator.yaml
	- $(kubectl) create -f ceph-cluster.yaml
	- $(kubectl) create -f ingress.yaml

configure_storage:
	- $(kubectl) create -f ceph-blockdevice.yaml

undeploy:
	- $(kubectl) delete -f ingress.yaml
	- $(kubectl) delete -f ceph-blockdevice.yaml
	- $(kubectl) delete -f ceph-cluster.yaml
	- $(kubectl) delete -f ceph-operator.yaml
	- $(kubectl) delete -f rbac.yaml
	- $(kubectl) delete namespace $(NAMESPACE)

config_dashboard:
	@ echo "Configure CEPH dashboard"
	$(eval ceph_toolbox=$(shell $(kubectl) get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}'))
	- $(kubectl) exec -it $(ceph_toolbox) -- bash -c "ceph dashboard ac-role-create $(CEPH_DASHBOARD_ROLE)"
	@ for scope in dashboard-settings log rgw prometheus grafana nfs-ganesha manager hosts rbd-image config-opt rbd-mirroring cephfs user osd pool monitor; do \
		$(kubectl) exec -it $(ceph_toolbox) -- bash -c "ceph dashboard ac-role-add-scope-perms $(CEPH_DASHBOARD_ROLE) $${scope} create delete read update"; \
	done
	- $(kubectl) exec -it $(ceph_toolbox) -- bash -c "ceph dashboard ac-user-set-roles admin $(CEPH_DASHBOARD_ROLE)"
	- $(kubectl) exec -it $(ceph_toolbox) -- bash -c "ceph dashboard ac-user-set-password $(CEPH_DASHBOARD_USER) $(CEPH_DASHBOARD_PASS)"

ceph_tools:
	- $(kubectl) exec -it $(shell $(kubectl) get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') bash