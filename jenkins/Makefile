.DEFAULT_GOAL := deploy

export DOMAIN_NAME ?= default
export NAMESPACE   ?= jenkins

VOLUME_TYPE ?= nfs
TIMEOUT     ?= 300
kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy-test:
	@echo $(kubectl)
	@echo Outputs:
	@echo password = secret
	@echo
	@echo Jenkins deployed
.PHONY: deploy-test

deploy:
	-$(kubectl) create namespace $(NAMESPACE)
	-$(kubectl) create configmap init-scripts --from-file=bin/
	-$(kubectl) create configmap script-approvals --from-file=approvals/
	-$(kubectl) label --overwrite configmap/init-scripts provider=agilestacks.com project=jenkins qualifier=init-scripts
	-$(kubectl) label --overwrite configmap/script-approvals provider=agilestacks.com project=jenkins qualifier=script-approvals

ifeq ($(VOLUME_TYPE),nfs)
	$(kubectl) apply -f job-nfs-mkdirs.yaml
	- $(SHELL) bin/wait_for.sh job nfs-mkdirs
endif
	$(kubectl) apply -f secrets.yaml
	$(kubectl) apply -f config.yaml
	$(kubectl) apply -f volume-$(VOLUME_TYPE).yaml
	$(kubectl) apply -f volume-claims.yaml
	$(kubectl) apply -f service.yaml
	$(kubectl) apply -f ingress.yaml
	$(kubectl) apply -f rbac.yaml
	$(kubectl) apply -f deployment.yaml

	$(MAKE) wait
.PHONY: deploy

undeploy:
	-$(kubectl) delete -f deployment.yaml
	-$(kubectl) delete -f rbac.yaml
	-$(kubectl) delete -f ingress.yaml
	-$(kubectl) delete -f volume-claims.yaml
	-$(kubectl) delete -f service.yaml
	-$(kubectl) delete -f secrets.yaml
	-$(kubectl) delete -f config.yaml
	-$(kubectl) delete -f volume-$(VOLUME_TYPE).yaml
ifeq ($(VOLUME_TYPE), nfs)
	-$(kubectl) delete -f job-nfs-mkdirs.yaml
endif
	-$(kubectl) delete configmap script-approvals
	-$(kubectl) delete configmap init-scripts
.PHONY: undeploy

wait:
	$(eval timeout=$(shell echo "`date +%s` + $(TIMEOUT)" | bc ))
	$(eval get_pod=$(kubectl) get pods -l 'project=jenkins,qualifier=master' --output=jsonpath='{.items..containerStatuses[?(@.ready==true)].containerID}')
	@printf "Waiting for Jenkins pod is up and running "

	@while [ `date +%s` -le "$(timeout)" ]; do \
		if [[ `$(get_pod)` ]]; then \
			echo " done"; \
			exit 0; \
		fi; \
		printf "."; \
		sleep 8; \
	done; \
	echo " ERROR timeout $(TIMEOUT)sec"; \
	exit 1


init-test:
	docker run \
		--rm -it \
		--env PATH=/opt/init/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
		-v $(realpath $(shell pwd))/bin:/opt/init/bin \
		-w /opt/init \
		--entrypoint=sh \
		alpine/git
#		docker.io/agilestacks/jenkins:2.89.3
.PHONY: init-test
