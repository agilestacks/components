.DEFAULT_GOAL := deploy

export NAMESPACE        ?= jenkins
export LOCAL_PORT       ?= 23867
export JENKINS_USER     ?= jenkins
export JENKINS_PASSWORD ?= secret
export JENKINS_PORT     ?= 8080
export PIPELINES        ?= asi-demo-nodejs asi-demo-java

JOB=""

kubectl := kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy:
	$(MAKE) connect
	for pipeline in "$(PIPELINES)"; do \
		$(MAKE) deploy-job JOB=$$pipeline ; \
	done
	$(MAKE) disconnect
.PHONY: deploy

undeploy:
	$(MAKE) connect
	for pipeline in $(PIPELINES) ; do \
		$(MAKE) undeploy-job JOB=$$pipeline ; \
	done
	$(MAKE) disconnect
.PHONY: deploy

deploy-job:
	curl -s -XPOST 'http://$(JENKINS_USER):$(JENKINS_PASSWORD)@localhost:$(LOCAL_PORT)/createItem?name=$(JOB)' \
		 --connect-timeout 10 \
		--data-binary @pipelines/$(JOB).xml \
		-H "Content-Type:text/xml" \
		> /dev/null
.PHONY: deploy-job

undeploy-job:
	curl -s -XPOST --connect-timeout 10 'http://$(JENKINS_USER):$(JENKINS_PASSWORD)@localhost:$(LOCAL_PORT)/job/$(JOB)/doDelete' >/dev/null
.PHONY: deploy-job

undeploy:
.PHONY: undeploy

connect: disconnect
	cd ../jenkins && $(MAKE) wait
	$(eval POD_NAME=$(shell $(kubectl) get pods -l "project=jenkins,qualifier=master" --output=jsonpath='{.items..metadata.name}'))
	@echo Start proxy to pod/$(POD_NAME)
	nohup $(kubectl) port-forward $(POD_NAME) $(LOCAL_PORT):${JENKINS_PORT} &
	@sleep 2
	@echo Connecting to vault at $(POD_NAME)
	@for i in $$(seq 1 60); do \
		if curl -sS http://localhost:$(LOCAL_PORT)/login -o /dev/null ; then \
			exit 0; \
		fi; \
		echo "Waiting for pod/$(POD_NAME) to connect ($$i)..."; \
		sleep 3; \
	done; \
	echo "Timeout for pod/$(POD_NAME)"; \
	exit 1
.PHONY: connect

disconnect:
	@echo Drop connection to jenkins pod
	@kill $(shell ps aux | grep -E "kubectl*|port-forward*|$(LOCAL_PORT):$(8080)" | grep -v grep | awk '{print $$2}' | xargs) 2>/dev/null | true
.PHONY: disconnect
