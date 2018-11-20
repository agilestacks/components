.DEFAULT_GOAL := deploy

export DOMAIN_NAME ?= default
export NAMESPACE   ?= jenkins

VOLUME_TYPE ?= nfs
TIMEOUT     ?= 600

KUBECTL_ARGS := --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
kubectl ?= kubectl $(KUBECTL_ARGS)

deploy:
	- $(kubectl) create namespace $(NAMESPACE)
	- $(kubectl) create configmap init-scripts --from-file=bin/
	- $(kubectl) create configmap script-approvals --from-file=approvals/
	- $(kubectl) label --overwrite configmap/init-scripts provider=agilestacks.com project=jenkins qualifier=init-scripts
	- $(kubectl) label --overwrite configmap/script-approvals provider=agilestacks.com project=jenkins qualifier=script-approvals

ifeq ($(VOLUME_TYPE),nfs)
	$(kubectl) apply --force -f job-nfs-mkdirs.yaml
	$(MAKE) wait_complete
endif
	$(kubectl) apply -f secrets.yaml
	$(kubectl) apply -f config.yaml
	$(kubectl) apply -f volume-$(VOLUME_TYPE).yaml
	$(kubectl) apply -f volume-claims.yaml
	$(kubectl) apply -f service.yaml
	$(kubectl) apply -f ingress.yaml
	$(kubectl) apply -f rbac.yaml
	$(kubectl) apply -f rbac-operator.yaml
	$(kubectl) apply -f deployment.yaml
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
	- $(kubectl) delete -f volume-$(VOLUME_TYPE).yaml
ifeq ($(VOLUME_TYPE), nfs)
	- $(kubectl) delete -f job-nfs-mkdirs.yaml
endif
	- $(kubectl) delete configmap script-approvals
	- $(kubectl) delete configmap init-scripts
	- $(MAKE) wait_shutdown

wait_complete:
	$(eval timeout=$(shell echo "`date +%s` + $(TIMEOUT)" | bc ))
	$(eval get_job=$(kubectl) get --output=json -f job-nfs-mkdirs.yaml)
	@ printf 'Waiting for job to finish'
	@ while [ `date +%s` -le "$(timeout)" ]; do \
		if [ `$(get_job) | jq -M '.status.succeeded or .status.failed'` == 'true' ]; then \
			printf ' done\n---\n'; \
			$(get_job) | jq .;\
			test `$(get_job) | jq -M '.status.succeeded' | xargs` == "1" && exit 0; \
		fi; \
		printf "."; \
		sleep 2; \
	done; \
	echo " ERROR timeout $(TIMEOUT)sec"; \
	exit 1

wait_up:
	$(eval timeout=$(shell echo "`date +%s` + $(TIMEOUT)" | bc ))
	$(eval count=$(shell $(kubectl) get pods --no-headers --output=json -l 'project=jenkins,qualifier=master' --output=json | jq -M '.items[0].spec.containers | length'))
	$(eval get_pod=$(kubectl) get pods --no-headers -l 'project=jenkins,qualifier=master' --output=jsonpath='{.items..containerStatuses[?(@.ready==true)].containerID}')
	@ printf "Waiting for Jenkins pod up and running [container count: $(count)]"

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
	@ printf "Waiting for Jenkins pod to terminate"

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
