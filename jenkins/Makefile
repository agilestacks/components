.DEFAULT_GOAL := deploy

export DOMAIN_NAME ?= default
export NAMESPACE   ?= jenkins

TIMEOUT     ?= 600

KUBECTL_ARGS := --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
kubectl ?= kubectl $(KUBECTL_ARGS)

deploy:
	- $(kubectl) create namespace $(NAMESPACE)
	- $(kubectl) create configmap init-scripts --from-file=bin/
	- $(kubectl) create configmap script-approvals --from-file=approvals/
	- $(kubectl) label --overwrite configmap/init-scripts provider=agilestacks.com project=jenkins qualifier=init-scripts
	- $(kubectl) label --overwrite configmap/script-approvals provider=agilestacks.com project=jenkins qualifier=script-approvals
ifeq ($(BUCKET_KIND), s3)
	- $(kubectl) apply -f config-storage-s3.yaml
endif
ifeq ($(BUCKET_KIND), ceph)
	- $(kubectl) apply -f config-storage-nfs.yaml
	- $(kubectl) apply -f volume-claims-nfs.yaml
endif
	- $(kubectl) apply -f secrets.yaml
	- $(kubectl) apply -f config.yaml
	- $(kubectl) apply -f volume-claims.yaml
	- $(kubectl) apply -f service.yaml
	- $(kubectl) apply -f ingress.yaml
	- $(kubectl) apply -f rbac.yaml
	- $(kubectl) apply -f rbac-operator.yaml
	- $(kubectl) apply -f deployment.yaml
	- $(MAKE) wait_up

undeploy:
	- $(kubectl) delete -f deployment.yaml
	- $(kubectl) delete -f rbac-operator.yaml
	- $(kubectl) delete -f rbac.yaml
	- $(kubectl) delete -f ingress.yaml
	- $(kubectl) delete -f volume-claims.yaml
	- $(kubectl) delete -f service.yaml
	- $(kubectl) delete -f secrets.yaml
	- $(kubectl) delete -f config.yaml
ifeq ($(BUCKET_KIND),s3)
	- $(kubectl) delete -f config-storage.yaml
endif
ifeq ($(BUCKET_KIND), ceph)
	- $(kubectl) delete -f config-storage-nfs.yaml
	# technical debt, the pvc is can't be deleted properly, that's why 'patch'
	- $(kubectl) patch pvc rook-nfs-pv-claim -p '{"metadata":{"finalizers":null}}'
	- $(kubectl) delete -f volume-claims-nfs.yaml
endif
	- $(kubectl) delete configmap script-approvals
	- $(kubectl) delete configmap init-scripts
	- $(MAKE) wait_shutdown

wait_up:
	$(eval timeout=$(shell echo "`date +%s` + $(TIMEOUT)" | bc ))
	$(eval count=$(shell $(kubectl) get pods --no-headers --output=json -l 'project=jenkins,qualifier=master' --output=json | jq -M '.items[0].spec.containers | length'))
	$(eval get_pod=$(kubectl) get pods --no-headers -l 'project=jenkins,qualifier=master' --output=jsonpath='{.items..containerStatuses[?(@.ready==true)].containerID}')
	@ echo "Waiting for Jenkins pod up and running [container count: $(count)]"

	@ while [ `date +%s` -le "$(timeout)" ]; do \
		if [[ `$(get_pod) | wc -w | xargs` -eq '$(count)' ]]; then \
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
	$(eval get_pod=$(kubectl) get pods --no-headers -l 'project=jenkins,qualifier=master' --output=json)
	@ echo "Waiting for Jenkins pod to terminate"

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

-include ../Mk/phonies
